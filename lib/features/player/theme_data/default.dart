import 'package:flutter/material.dart';

class DefaultTheme {
  // Primary Colors
  static const Color themeColor = Color(0xFF1A1A1A);
  static const Color primaryColor1 = Color(0xFFFFFFFF);
  static const Color primaryColor2 = Color(0xFF9E9E9E);
  static const Color accentColor2 = Color(0xFF6200EA);

  // Text Styles
  static const TextStyle secondoryTextStyle = TextStyle(
    color: primaryColor2,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle secondoryTextStyleMedium = TextStyle(
    color: primaryColor2,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tertiaryTextStyle = TextStyle(
    color: primaryColor1,
    fontSize: 12,
    fontWeight: FontWeight.w300,
  );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    primaryColor: accentColor2,
    scaffoldBackgroundColor: themeColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: themeColor,
      foregroundColor: primaryColor1,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xCC1A1A1A), // themeColor.withOpacity(0.8) equivalent
      elevation: 4,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryColor1),
      bodyMedium: TextStyle(color: primaryColor2),
      titleLarge: TextStyle(color: primaryColor1, fontWeight: FontWeight.bold),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    primaryColor: accentColor2,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 4,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.grey),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
  );
}