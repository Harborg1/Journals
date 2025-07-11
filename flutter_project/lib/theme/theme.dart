import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey.shade100, // softer than white
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade100, // matches scaffold
    foregroundColor: Colors.black,         // readable, clean
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,  // primary brand color
      foregroundColor: Colors.white,       // strong contrast
    ),
  ),
);


ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey.shade800,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade800, // Or grey.shade900 for a seamless look
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
  ),
);
