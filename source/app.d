import std.stdio;
import std.range.primitives : isInputRange, isInfinite, ElementEncodingType;
import std.traits : isSomeChar, isConvertibleToString;
import std.datetime : abs, SysTime, Clock, seconds;
import std.file : DirEntry;


auto listdir(R)(R pathname)
    if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) && !isConvertibleToString!R)
{
  import std.algorithm;
  import std.array;
  import std.file;
  import std.path;

  /*
  return std.file.dirEntries(pathname, SpanMode.shallow).filter!(a => a.isFile)
    .map!((return a) => std.path.baseName(a.name))
    .array;
    */
  return std.file.dirEntries(pathname, SpanMode.shallow);
}

string getPermissionString(DirEntry entry)
{
  import std.file : getLinkAttributes, attrIsDir, attrIsFile, attrIsSymlink;
  import util.coloring;

  auto att = entry.linkAttributes();

  string ret;

  if (attrIsDir(att))
  {
    ret ~= coloring("d", Ground.foreground, Color.magenta).styling(Style.bold);
  }
  else if (attrIsSymlink(att))
  {
    ret ~= coloring("l", Ground.foreground, Color.cyan).styling(Style.bold);
  }
  else
  {
    ret ~= ".".styling(Style.bold);
  }

  auto convert = (uint num) {
    string s;
    s ~= ((num >> 2) & 1) ? coloring("r", Ground.foreground, Color.yellow) : "-";
    s ~= ((num >> 1) & 1) ? coloring("w", Ground.foreground, Color.red) : "-";
    s ~= (num & 1) ? coloring("x", Ground.foreground, Color.green) : "-";

    return s;
  };

  uint owner = (att >> 6) & 0b111;
  uint group = (att >> 3) & 0b111;
  uint other = att & 0b111;

  ret ~= styling(convert(owner), Style.bold) ~ convert(group) ~ convert(other);

  import std.format;

  return ret;
}

string getFileSize(DirEntry entry)
{
  import std.file : getSize;
  import std.format : format;
  import std.container.array;

  ulong size = entry.size();

  struct prefix
  {
    char c;
    ulong num;
    this(char c, ulong num)
    {
      this.c = c;
      this.num = num;
    }
  }

  auto prefixes = Array!prefix();
  string prefixStr = "EPTGMK";
  foreach (idx, c; prefixStr)
  {
    prefixes ~= prefix(c, 1uL << ((prefixStr.length - idx) * 10));
  }

  string ret;

  foreach (p; prefixes)
  {
    if (size / p.num != 0)
    {
      ret = format("%.1f%s", cast(double)(size) / p.num, p.c);
      break;
    }
  }

  if (ret == "")
  {
    ret = format("%s", size);
  }

  import util.coloring;

  if (entry.isDir)
  {
    return coloring(format("%4s", ret), Ground.foreground, Color.green).styling(Style.underline);
  }
  else
  {
    return coloring(format("%4s", ret), Ground.foreground, Color.green).styling(Style.bold);
  }
}

string getColoringFileName(DirEntry entry)
{
  import util.coloring;
  import std.path : baseName;

  auto att = entry.linkAttributes();

  string ret;

  if (entry.isDir)
  {
    ret = coloring(baseName(entry.name), Ground.foreground, Color.magenta).styling(Style.bold);
  }
  else if (entry.isSymlink)
  {
    ret = coloring(baseName(entry.name), Ground.foreground, Color.cyan);
  }
  else
  {
    ret = baseName(entry.name);
  }

  return ret;
}

string convertDatetimeString(SysTime time)
{
  import std.format : format;
  import util.coloring;
  import std.uni : toUpper;

  auto month = format("%s", time.month);

  return format("%s %02s %02s:%02s", cast(char)(toUpper(month[0])) ~ month[1 .. $], time.day, time.hour, time
      .minute).coloring(Ground.foreground, Color.magenta);
}

void main(string[] args)
{
  import std.file : getAttributes, getSize, getTimes, exists, isDir;
  import std.path : baseName;
  import std.datetime : abs, SysTime, Clock, seconds;
  import std.algorithm : sort, map, filter;
  import std.array;
  import std.getopt;

  bool all;

  auto helpInfomation = getopt(
      args,
      "all|a", "show hidden files", &all
      );

  if (helpInfomation.helpWanted)
  {
    defaultGetoptPrinter("nessie", helpInfomation.options);
    return;
  }

  DirEntry[] paths;

  if (args.length == 1)
  {
    paths ~= DirEntry(".");
  }

  foreach (ref pathString; args[1 .. $])
  {
    if (!exists(pathString))
    {
      writefln("%s: No such file or directory\n", pathString);
      continue;
    }

    paths ~= DirEntry(pathString);
  }

  auto filePaths = paths.filter!(x => !x.isDir).array;
  auto dirPaths = paths.filter!(x => x.isDir).array;

  foreach (idx, ref path; filePaths)
  {
    auto permission = getPermissionString(path);
    auto size = getFileSize(path);
    auto filename = getColoringFileName(path);
    SysTime accessTime, modificationTime;
    getTimes(path, accessTime, modificationTime);
    writefln("%s %s %s %s", permission, size, convertDatetimeString(accessTime), filename);

    if (idx + 1 == filePaths.length)
    {
      writeln();
    }
  }

  foreach (ref path; dirPaths)
  {
    if (dirPaths.length != 1)
    {
      writefln("%s:", path);
    }

    auto files = listdir(path.name).array;
    sort!((a, b) => (a.name < b.name))(files);

    foreach (idx, const ref file; files)
    {
      auto permission = getPermissionString(file);
      auto size = getFileSize(file);
      auto filename = getColoringFileName(file);
      SysTime accessTime, modificationTime;
      getTimes(file, accessTime, modificationTime);
      writefln("%s %s %s %s", permission, size, convertDatetimeString(accessTime), filename);

      if (idx + 1 == files.length)
      {
        writeln();
      }
    }
  }
}
