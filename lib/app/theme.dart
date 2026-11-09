import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colours
  static const Color primary = Color(0xFF087F8C);
  static const Color secondary = Color(0xFF42A5B5);

  static const Color background = Color(0xFFF5F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF172B3A);
  static const Color textSecondary = Color(0xFF718096);

  // Dark theme colours
  static const Color darkPrimary = Color(0xFF2DD4BF);
  static const Color darkSecondary = Color(0xFF5EEAD4);

  static const Color darkBackground = Color(0xFF101827);
  static const Color darkSurface = Color(0xFF1E293B);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFA7B4C5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: Color(0xFFDC2626),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      dividerColor: const Color(0xFFE2E8F0),

      iconTheme: const IconThemeData(
        color: textSecondary,
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Color(0xFF062B2A),
        secondary: darkSecondary,
        onSecondary: Color(0xFF062B2A),
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: Color(0xFFF87171),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      dividerColor: const Color(0xFF334155),

      iconTheme: const IconThemeData(
        color: Color(0xFFCBD5E1),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}