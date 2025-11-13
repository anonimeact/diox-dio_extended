/// A collection of static constants for ANSI escape codes.
///
/// These codes are used to add color and formatting to text in a terminal
/// that supports ANSI standards. Use these constants to make console output
/// more readable and organized.
///
/// To apply a color, prepend the desired constant to your string and
/// append [AnsiColor.reset] to the end to ensure the color does not
/// "bleed" into subsequent console text.
///
/// Example:
/// ```dart
/// print('${AnsiColor.red}Error: Something went wrong!${AnsiColor.reset}');
/// ```
class AnsiColor {
  static const String reset = '\x1b[0m';
  static const String black = '\x1b[30m';
  static const String red = '\x1b[31m';
  static const String green = '\x1b[32m';
  static const String yellow = '\x1b[33m';
  static const String blue = '\x1b[34m';
  static const String magenta = '\x1b[35m';
  static const String cyan = '\x1b[36m';
  static const String white = '\x1b[37m';
  static const String brightCyan = '\x1b[96m';
  static const String brightGreen = '\x1b[92m';
}
