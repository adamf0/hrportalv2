import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Design Tokens and System Theme for HR Portal.
/// All colors, typography styles, and theme extensions are managed here.
class AppTheme {
  // Core Brand Colors
  static const Color primary = Color(0xFF003D9B);
  static const Color primaryLight = Color(0xFF0052CC);
  static const Color secondary = Color(0xFF535F73);
  static const Color background = Color(0xFFF8F9FB);
  static const Color cardBackground = Colors.white;

  // Neutral Colors
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF434654);
  static const Color outlineVariant = Color(0x4DC3C6D6);
  static const Color border = Color(0xFFEDEEF0);
  static const Color divider = Color(0xFFE0E2E5);

  // Status & Semantic Colors
  static const Color success = Color(0xFF137333);
  static const Color successContainer = Color(0xFFE6F4EA);
  static const Color warning = Color(0xFFB06000);
  static const Color warningContainer = Color(0xFFFEF7E0);
  static const Color info = Color(0xFF1A73E8);
  static const Color infoContainer = Color(0xFFE8F0FE);
  static const Color error = Color(0xFFC5221F);
  static const Color errorContainer = Color(0xFFFCE8E6);

  /// Main MaterialApp Theme Data
  static ThemeData lightTheme(BuildContext context) {
    final baseTextTheme =
        GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: background,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outlineVariant: outlineVariant,
        surfaceContainer: border,
        error: error,
        onError: Colors.white,
        errorContainer: errorContainer,
        onErrorContainer: error,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: onSurface,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: primary,
          fontSize: 16,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
    );
  }
}
