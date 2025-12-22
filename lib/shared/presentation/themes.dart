import 'package:flutter/material.dart';

class Themes {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 18, 80, 205),
      foregroundColor: Color(0xFFF9F9F9),
    ),
    colorScheme: ColorScheme.light(
      primary: Color.fromARGB(255, 18, 80, 205),
      surfaceContainerLowest: Color(0xFFF9F9FA),
      surfaceContainerLow: Color(0xFFDBDBDC),
      surfaceContainer: Color(0xFFD1D1D2),
      surfaceContainerHighest: Color(0xFF505968),
    ),
    popupMenuTheme: PopupMenuThemeData(color: Colors.white),
  );
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF10151B),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 4, 33, 101),
      foregroundColor: Color(0xFFF9F9F9),
    ),
    colorScheme: ColorScheme.dark(
      primary: Color.fromARGB(255, 18, 80, 205),
      surfaceContainerLowest: Color(0xFF090B0E),
      surfaceContainerLow: Color(0xFF27292B),
      surfaceContainer: Color(0xFF313235),
      surfaceContainerHighest: Color(0xFF94ABBC),
    ),
  );
}
