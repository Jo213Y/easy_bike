import 'package:flutter/material.dart';

/// تعريف الثيمين (الفاتح والغامق) بتاعين التطبيق
class AppTheme {
  static const Color _purple = Colors.purple;

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F3F5),
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _purple,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF3F3F5),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _purple,
        unselectedItemColor: Colors.grey,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1C1C1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: _purple,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        selectedItemColor: _purple,
        unselectedItemColor: Colors.grey,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1C1C1E)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }
}
