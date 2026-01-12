import 'package:flutter/material.dart';

class Themes {
  static ThemeData darkTheme = ThemeData(
    primaryColor: Color(0xFFD71921),
    scaffoldBackgroundColor: Color(0xFF070F17),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 41, 92, 43),
      foregroundColor: Color(0xFFF9F9F9),
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
