module util.coloring;

enum Ground: uint
{
  foreground = 3,
  background,
}

enum Color : uint
{
  black = 0,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  def = 9
}

enum Style : uint
{
  bold = 1,
  faint,
  italic,
  underline,
  blink,
  fast_blink,
  reverse,
  conceal,
  strike,
  doubleUnderline = 21
}


string coloring(string s, Ground g, Color c)
{
  import std.format : format;

  return format("\x1b[%d%dm%s\x1b[%d%dm", g, c, s, g, Color.def);
}

string styling(string s, Style st)
{
  import std.format : format;

  uint resetValue;
  if (st == Style.bold)
  {
    resetValue = 22;
  }
  else if (st == Style.doubleUnderline)
  {
    resetValue = 24;
  }
  else
  {
    resetValue = cast(uint)(st) + 20u;
  }

  return format("\x1b[%dm%s\x1b[%dm", st, s, resetValue);
}