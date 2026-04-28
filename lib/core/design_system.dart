import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced Design System for AWFPS
/// Provides consistent spacing, typography, and UI patterns
class AppDesignSystem {
  // SPACING SCALE (8px base unit)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // BORDER RADIUS SCALE
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 999.0;

  // ELEVATION SCALE
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationMax = 12.0;

  // TOUCH TARGET SIZES
  static const double minTouchSize = 44.0; // Accessibility standard
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 40.0;
  static const double compactButtonHeight = 36.0;

  // ANIMATION DURATIONS
  static const Duration durationQuick = Duration(milliseconds: 150);
  static const Duration durationSmooth = Duration(milliseconds: 300);
  static const Duration durationMedium = Duration(milliseconds: 500);
  static const Duration durationSlow = Duration(milliseconds: 800);

  /// Enhanced Text Theme with better hierarchy
  static TextTheme createTextTheme({required bool isDark}) {
    final baseTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      // Display styles - Large headlines
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      // Headline styles
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.3,
      ),
      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.5,
      ),
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
      ),
    );
  }

  /// Enhanced button styles
  static ButtonStyle getPrimaryButtonStyle({required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? const Color(0xFF4CAF50)
          : const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      elevation: elevationNone,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
    );
  }

  static ButtonStyle getSecondaryButtonStyle({required bool isDark}) {
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? Colors.white : const Color(0xFF2E7D32),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      side: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFFE5E7EB),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  static ButtonStyle getTertiaryButtonStyle({required bool isDark}) {
    return TextButton.styleFrom(
      foregroundColor: isDark ? Colors.white : const Color(0xFF2E7D32),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing20,
        vertical: spacing12,
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    );
  }

  /// Input decoration with better validation feedback
  static InputDecorationTheme getInputDecorationTheme({required bool isDark}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing20,
        vertical: spacing16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
      ),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
      ),
      helperStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFDC2626),
      ),
    );
  }

  /// Card theme with better shadow and border
  static CardThemeData getCardTheme({required bool isDark}) {
    return CardThemeData(
      elevation: elevationNone,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: spacing8,
        horizontal: spacing12,
      ),
    );
  }

  /// App bar theme
  static AppBarTheme getAppBarTheme({required bool isDark}) {
    return AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF1B5E20),
      centerTitle: false,
      elevation: elevationNone,
      scrolledUnderElevation: elevationLow,
      titleTextStyle: TextStyle(
        inherit: true,
        color: isDark ? Colors.white : const Color(0xFF1B5E20),
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}
