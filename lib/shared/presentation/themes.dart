import 'package:flutter/material.dart';

class Themes {
  static const _orange = Color(0xFFFF7A1A);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _orange,
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF111215),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: Colors.grey[300],
    ),
    colorScheme: ColorScheme.light(
      primary: _orange,
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF0F0F0),
      surfaceContainer: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF9E9E9E),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: "Nothing", fontSize: 28),
      titleMedium: TextStyle(fontFamily: "Nothing", fontSize: 24),
      titleSmall: TextStyle(fontFamily: "Nothing", fontSize: 20),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _orange,
    scaffoldBackgroundColor: Color(0xFF0B0C0E),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFE6E7EA),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: Color(0xFF2A2B2F),
    ),
    colorScheme: ColorScheme.dark(
      primary: _orange,
      surfaceContainerLowest: Color(0xFF0D0E11),
      surfaceContainerLow: Color(0xFF111215),
      surfaceContainer: Color(0xFF17181C),
      surfaceContainerHighest: Color(0xFF6B707A),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: "Nothing", fontSize: 28),
      titleMedium: TextStyle(fontFamily: "Nothing", fontSize: 24),
      titleSmall: TextStyle(fontFamily: "Nothing", fontSize: 20),
    ),
  );
}
