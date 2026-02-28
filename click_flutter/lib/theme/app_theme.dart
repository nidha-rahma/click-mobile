import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryLight = Color(0xFF10B981); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700

  static const Color highPriority = Color(0xFFE53935); // Red (HSL 0, 72%, 51%)
  static const Color mediumPriority = Color(
    0xFFF59E0B,
  ); // Amber (HSL 38, 92%, 50%)
  static const Color lowPriority = Color(
    0xFF3B82F6,
  ); // Blue (HSL 217, 91%, 60%)

  // Light Mode Colors
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Color(0xFFFAFAFA); // HSL(0, 0%, 98%)
  static const Color textLight = Color(0xFF141A23); // HSL(220, 20%, 10%)
  static const Color mutedTextLight = Color(0xFF6B7280); // HSL(220, 10%, 46%)

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Colors.white;
  static const Color mutedTextDark = Color(0xFFA1A1AA);

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        surface: surfaceLight,
        onSurface: textLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.inter(
          color: textLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(color: textLight),
        bodyMedium: GoogleFonts.inter(color: textLight),
        labelSmall: GoogleFonts.jetBrainsMono(color: mutedTextLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        surface: surfaceDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              color: textDark,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.inter(
              color: textDark,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(color: textDark),
            bodyMedium: GoogleFonts.inter(color: textDark),
            labelSmall: GoogleFonts.jetBrainsMono(color: mutedTextDark),
          ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
