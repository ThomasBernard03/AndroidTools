import 'package:flutter/material.dart';

class Themes {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    drawerTheme: DrawerThemeData(backgroundColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF4FAF53),
      foregroundColor: Color(0xFFF9F9F9),
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF4FAF53),
      surfaceContainerLowest: Color(0xFFF9F9FA),
      surfaceContainerLow: Color(0xFFDBDBDC),
      surfaceContainer: Color(0xFFD1D1D2),
      surfaceContainerHighest: Color(0xFF505968),
    ),
    popupMenuTheme: PopupMenuThemeData(color: Colors.white),
    cardTheme: CardThemeData(color: const Color.fromARGB(255, 227, 227, 227)),
  );
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF10151B),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 41, 92, 43),
      foregroundColor: Color(0xFFF9F9F9),
    ),
    colorScheme: ColorScheme.dark(
      primary: Color.fromARGB(255, 41, 92, 43),
      surfaceContainerLowest: Color(0xFF090B0E),
      surfaceContainerLow: Color(0xFF27292B),
      surfaceContainer: Color(0xFF313235),
      surfaceContainerHighest: Color(0xFF94ABBC),
    ),
  );
}
