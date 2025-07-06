import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Light Theme Colors with improved contrast and softer tones
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6366F1), // Indigo - more modern than blue
    onPrimary: Colors.white,
    secondary: Color(0xFF06B6D4), // Cyan - more vibrant and modern
    onSecondary: Colors.white,
    tertiary: Color(0xFF8B5CF6), // Purple accent
    onTertiary: Colors.white,
    error: Color(0xFFEF4444), // Softer red
    onError: Colors.white,
    background: Color(0xFFFAFAFA), // Slightly warmer background
    onBackground: Color(0xFF0F172A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    surfaceVariant: Color(0xFFF1F5F9), // Light gray for cards
    onSurfaceVariant: Color(0xFF64748B),
    outline: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000).withOpacity(0.04),
  );

  // Modern Dark Theme Colors with better contrast and warmer tones
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8), // Lighter indigo for dark mode
    onPrimary: Color(0xFF1E1B4B),
    secondary: Color(0xFF22D3EE), // Brighter cyan for dark mode
    onSecondary: Color(0xFF0C4A6E),
    tertiary: Color(0xFFA855F7), // Brighter purple
    onTertiary: Color(0xFF581C87),
    error: Color(0xFFF87171), // Softer red for dark mode
    onError: Color(0xFF7F1D1D),
    background: Color(0xFF0F172A), // Deep navy
    onBackground: Color(0xFFF8FAFC),
    surface: Color(0xFF1E293B), // Slate gray
    onSurface: Color(0xFFF8FAFC),
    surfaceVariant: Color(0xFF334155), // Medium slate for cards
    onSurfaceVariant: Color(0xFFCBD5E1),
    outline: Color(0xFF475569),
    shadow: Color(0xFF000000).withOpacity(0.2),
  );

  // Modern Typography with better hierarchy and readability
  static final _textTheme = TextTheme(
    // Main headings
    displayLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.6,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.4,
    ),
    
    // Section headings
    headlineLarge: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
    ),
    
    // Titles
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
    ),
    
    // Body text
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0.1,
    ),
    
    // Labels
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.2,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.3,
    ),
  );

  // Modern component themes
  static final _lightComponentThemes = {
    // Cards with subtle shadows and rounded corners
    'cardTheme': CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _lightColorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: _lightColorScheme.surface,
      shadowColor: _lightColorScheme.shadow,
    ),
    
    // Modern elevated buttons
    'elevatedButtonTheme': ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Modern text buttons
    'textButtonTheme': TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Modern outlined buttons
    'outlinedButtonTheme': OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(
          color: _lightColorScheme.outline,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Modern input decoration
    'inputDecorationTheme': InputDecorationTheme(
      filled: true,
      fillColor: _lightColorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _lightColorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _lightColorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _lightColorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _lightColorScheme.error,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Modern app bar
    'appBarTheme': AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
      centerTitle: false,
      titleSpacing: 0,
    ),
  };

  static final _darkComponentThemes = {
    // Cards for dark theme
    'cardTheme': CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _darkColorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: _darkColorScheme.surface,
      shadowColor: _darkColorScheme.shadow,
    ),
    
    // Dark theme elevated buttons
    'elevatedButtonTheme': ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Dark theme text buttons
    'textButtonTheme': TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Dark theme outlined buttons
    'outlinedButtonTheme': OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(
          color: _darkColorScheme.outline,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Dark theme input decoration
    'inputDecorationTheme': InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _darkColorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _darkColorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _darkColorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _darkColorScheme.error,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Dark theme app bar
    'appBarTheme': AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
      centerTitle: false,
      titleSpacing: 0,
    ),
  };

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    textTheme: _textTheme,
    scaffoldBackgroundColor: _lightColorScheme.background,
    cardTheme: _lightComponentThemes['cardTheme'] as CardTheme,
    elevatedButtonTheme: _lightComponentThemes['elevatedButtonTheme'] as ElevatedButtonThemeData,
    textButtonTheme: _lightComponentThemes['textButtonTheme'] as TextButtonThemeData,
    outlinedButtonTheme: _lightComponentThemes['outlinedButtonTheme'] as OutlinedButtonThemeData,
    inputDecorationTheme: _lightComponentThemes['inputDecorationTheme'] as InputDecorationTheme,
    appBarTheme: _lightComponentThemes['appBarTheme'] as AppBarTheme,
    dividerColor: _lightColorScheme.outline.withOpacity(0.2),
    splashFactory: InkRipple.splashFactory,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    textTheme: _textTheme,
    scaffoldBackgroundColor: _darkColorScheme.background,
    cardTheme: _darkComponentThemes['cardTheme'] as CardTheme,
    elevatedButtonTheme: _darkComponentThemes['elevatedButtonTheme'] as ElevatedButtonThemeData,
    textButtonTheme: _darkComponentThemes['textButtonTheme'] as TextButtonThemeData,
    outlinedButtonTheme: _darkComponentThemes['outlinedButtonTheme'] as OutlinedButtonThemeData,
    inputDecorationTheme: _darkComponentThemes['inputDecorationTheme'] as InputDecorationTheme,
    appBarTheme: _darkComponentThemes['appBarTheme'] as AppBarTheme,
    dividerColor: _darkColorScheme.outline.withOpacity(0.2),
    splashFactory: InkRipple.splashFactory,
  );
}