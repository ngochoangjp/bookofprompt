import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3B82F6), // Blue
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF10B981), // Green
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFF8B5CF6), // Purple
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    onBackground: Color(0xFF1F2937),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFF64748B),
    outline: Color(0xFFCBD5E1),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF1F5F9),
    inversePrimary: Color(0xFF60A5FA),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA), // Light Blue
    onPrimary: Color(0xFF0F172A),
    secondary: Color(0xFF34D399), // Light Green
    onSecondary: Color(0xFF0F172A),
    tertiary: Color(0xFFA78BFA), // Light Purple
    onTertiary: Color(0xFF0F172A),
    error: Color(0xFFF87171),
    onError: Color(0xFF0F172A),
    background: Color(0xFF0F172A),
    onBackground: Color(0xFFF1F5F9),
    surface: Color(0xFF1E293B),
    onSurface: Color(0xFFF1F5F9),
    surfaceVariant: Color(0xFF334155),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF475569),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: Color(0xFF3B82F6),
  );

  // Typography with improved sizes and Roboto font
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return GoogleFonts.robotoTextTheme().copyWith(
      // Headers
      headlineLarge: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: colorScheme.onBackground,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: colorScheme.onBackground,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 18, // Increased from 16
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: colorScheme.onBackground,
      ),
      
      // Titles
      titleLarge: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      
      // Body text with improved sizes
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16, // Increased from 14
        fontWeight: FontWeight.w500, // Increased from w400
        height: 1.3, // Decreased from 1.4
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 15, // Increased from 14
        fontWeight: FontWeight.w500, // Increased from w400
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 13, // Increased from 12
        fontWeight: FontWeight.w500, // Increased from w400
        height: 1.3,
        color: colorScheme.onSurfaceVariant,
      ),
      
      // Labels
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // Code editor theme
  static TextStyle codeTextStyle(ColorScheme colorScheme) {
    return GoogleFonts.firaCode(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: colorScheme.onSurface,
    );
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    textTheme: _buildTextTheme(_lightColorScheme),
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightColorScheme.onSurface,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: _lightColorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightColorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _lightColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // List Tile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: _lightColorScheme.outline,
      thickness: 1,
      space: 1,
    ),
    
    // Scrollbar
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(_lightColorScheme.outline),
      trackColor: MaterialStateProperty.all(_lightColorScheme.surfaceVariant),
      radius: const Radius.circular(4),
      thickness: MaterialStateProperty.all(8),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    textTheme: _buildTextTheme(_darkColorScheme),
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkColorScheme.onSurface,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: _darkColorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _darkColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // List Tile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: _darkColorScheme.outline,
      thickness: 1,
      space: 1,
    ),
    
    // Scrollbar
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(_darkColorScheme.outline),
      trackColor: MaterialStateProperty.all(_darkColorScheme.surfaceVariant),
      radius: const Radius.circular(4),
      thickness: MaterialStateProperty.all(8),
    ),
  );
  
  // Helper methods for custom colors
  static Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF10B981)
        : const Color(0xFF34D399);
  }
  
  static Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFF59E0B)
        : const Color(0xFFFBBF24);
  }
  
  static Color infoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF3B82F6)
        : const Color(0xFF60A5FA);
  }
  
  // Custom shadows
  static List<BoxShadow> cardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
  
  static List<BoxShadow> elevatedShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}