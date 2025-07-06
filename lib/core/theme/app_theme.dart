import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors (as per document)
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3B82F6),
    onPrimary: Colors.white,
    secondary: Color(0xFF10B981),
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    background: Color(0xFFF8FAFC),
    onBackground: Color(0xFF1F2937),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
  );

  // Dark Theme Colors (as per document)
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF0F172A),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF0F172A),
    error: Colors.red,
    onError: Colors.black,
    background: Color(0xFF0F172A),
    onBackground: Color(0xFFF1F5F9),
    surface: Color(0xFF1E293B),
    onSurface: Color(0xFFF1F5F9),
  );

  // Typography (as per document) - Optimized for Windows clarity
  static final _textTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(
      fontSize: 24, 
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    headlineSmall: GoogleFonts.roboto(
      fontSize: 18, 
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16, 
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 15, 
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0,
    ),
    labelLarge: GoogleFonts.roboto(
      fontSize: 14, 
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 13, 
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.1,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    textTheme: _textTheme,
    scaffoldBackgroundColor: _lightColorScheme.background,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    textTheme: _textTheme,
    scaffoldBackgroundColor: _darkColorScheme.background,
  );
} 