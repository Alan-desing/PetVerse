import 'package:flutter/material.dart';

/// Defines the shared visual language for PetVerse.
abstract final class AppTheme {
  /// PetVerse's primary orange color.
  static const Color orange = Color(0xFFFF7043);

  /// Warm page background used by the authentication experience.
  static const Color canvas = Color(0xFFFFF9F5);

  /// Deep ink color used for headings and body copy.
  static const Color ink = Color(0xFF263238);

  /// The default light Material theme.
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: orange, surface: Colors.white),
    scaffoldBackgroundColor: canvas,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        color: ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: Color(0xFF546168), height: 1.5),
      bodyMedium: TextStyle(color: Color(0xFF657279), height: 1.45),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F8F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: const TextStyle(color: Color(0xFF9AA3A7), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF667278)),
      prefixIconColor: const Color(0xFF8A959A),
      suffixIconColor: const Color(0xFF8A959A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E9E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E9E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: orange, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9534F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
