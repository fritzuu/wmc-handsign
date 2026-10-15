import 'package:flutter/material.dart';

/// Sistem tema monokrom modern (Black & White Minimalist Design System)
/// untuk aplikasi WMC Simulator.
class AppTheme {
  AppTheme._();

  // --- Palet Warna Monokrom Modern ---
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkNavy = Color(0xFF0A0A0A);
  static const Color deepNavy = Color(0xFF121212);
  static const Color cardBlack = Color(0xFF171717);

  // Modern Neutral Surfaces
  static const Color white = Colors.white;
  static const Color surfaceBackground = Color(0xFFFAFAFA);
  static const Color cardSurface = Colors.white;
  static const Color desktopCanvas = Color(0xFF121212);

  // Grayscale Text & Lines
  static const Color textPrimary = Color(0xFF0F0F0F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color darkBorder = Color(0xFF262626);

  // Status Tones (Subtle, High-Legibility)
  static const Color successGreen = Color(0xFF15803D);
  static const Color lightGreenBg = Color(0xFFF0FDF4);
  static const Color warningOrange = Color(0xFFB45309);
  static const Color lightOrangeBg = Color(0xFFFFFBEB);
  static const Color errorRed = Color(0xFFB91C1C);
  static const Color lightRedBg = Color(0xFFFEF2F2);

  // Backward-compatible monochrome aliases
  static const Color primaryBlue = Color(0xFF0A0A0A);
  static const Color accentBlue = Color(0xFF525252);
  static const Color lightBlueBg = Color(0xFFF3F4F6);

  // --- Dimensi & Radius ---
  static const double cardBorderRadius = 14.0;
  static const double buttonBorderRadius = 10.0;
  static const double chipBorderRadius = 8.0;

  /// Tema Terang (Light Mode) Monokrom Modern.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: darkNavy,
        onPrimary: Colors.white,
        secondary: Color(0xFF404040),
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: surfaceBackground,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: surfaceBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: dividerColor, width: 1.0),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFFF3F4F6),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: textPrimary, size: 22);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1.0,
        space: 16,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: dividerColor, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
