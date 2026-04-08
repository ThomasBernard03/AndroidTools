import 'package:flutter/material.dart';

class Themes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFFD71921),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Color(0xFF000000),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: Colors.grey[300],
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFFD71921),
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
    primaryColor: Color(0xFFD71921),
    scaffoldBackgroundColor: Color(0xFF070F17),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 41, 92, 43),
      foregroundColor: Color(0xFFF9F9F9),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFD71921),
      surfaceContainerLowest: Color(0xFF090B0E),
      surfaceContainerLow: Color(0xFF27292B),
      surfaceContainer: Color(0xFF313235),
      surfaceContainerHighest: Color(0xFF94ABBC),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: "Nothing", fontSize: 28),
      titleMedium: TextStyle(fontFamily: "Nothing", fontSize: 24),
      titleSmall: TextStyle(fontFamily: "Nothing", fontSize: 20),
    ),
  );
}
