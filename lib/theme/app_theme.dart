import 'package:flutter/material.dart';

/// Sistem tema terpusat (Design System) untuk aplikasi WMC Simulator
/// berbasis spesifikasi Material Design 3 dan PRD v1.0/v2.0.
class AppTheme {
  AppTheme._();

  // --- Palet Warna Utama (PRD Wireframes) ---
  static const Color darkNavy = Color(0xFF0D1B2A);
  static const Color deepNavy = Color(0xFF1A237E);
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color lightBlueBg = Color(0xFFE3F2FD);
  static const Color surfaceBackground = Color(0xFFFAFAFA);
  static const Color cardSurface = Colors.white;

  // Status Colors
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color lightOrangeBg = Color(0xFFFFF3E0);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color lightRedBg = Color(0xFFFFEBEE);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // --- Konstanta Dimensi & Radius ---
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 24.0;
  static const double chipBorderRadius = 20.0;

  /// Tema Terang (Light Mode) utama aplikasi.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: accentBlue,
        surface: surfaceBackground,
        onSurface: textPrimary,
        error: errorRed,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: dividerColor, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: lightBlueBg,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.8,
        space: 16,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
