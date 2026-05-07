import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

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
  static const double spacing64 = 64.0;

  // ICON SIZES
  static const double iconSizeMini = 16.0;
  static const double iconSizeSmall = 18.0;

  // BORDER RADIUS SCALE
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radius2XLarge = 32.0;
  static const double radiusRound = 999.0;

  // ANIMATION DURATIONS
  static const Duration durationQuick = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ELEVATION & SHADOWS
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  // GLASSMORPHISM DECORATION
  static BoxDecoration glassDecoration({
    double blur = 12.0,
    double opacity = 0.7,
    double borderRadius = radiusXLarge,
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
    );
  }

  // COMMON TEXT STYLES (for direct access)
  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// Enhanced Text Theme with better hierarchy
  static TextTheme createTextTheme({required bool isDark}) {
    final baseTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final color = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Slate.shade400 : AppColors.textSecondary;

    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.1,
        color: color,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: color,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: color,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Button Styles
  static ButtonStyle primaryButton({required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      elevation: 0,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  static ButtonStyle secondaryButton({required bool isDark}) {
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      side: BorderSide(color: isDark ? Slate.shade700 : Slate.shade200),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  static ButtonStyle glassButton({required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.1),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      elevation: 0,
    );
  }
}

/// A specialized widget for glassmorphic effects
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.borderRadius = AppDesignSystem.radiusXLarge,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(opacity * 2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: card,
      );
    }
    return card;
  }
}

/// Premium Dashboard Card
class DashboardCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadow;

  const DashboardCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacing24),
      decoration: BoxDecoration(
        color: color ?? (isDark ? Slate.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius ?? AppDesignSystem.radiusXLarge),
        boxShadow: shadow ?? AppDesignSystem.softShadow,
        border: Border.all(
          color: isDark ? Slate.shade800 : Slate.shade100,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// A specialized widget for glassmorphic icons
class GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double borderRadius;

  const GlassIcon(this.icon, {
    super.key, 
    this.color = AppColors.primary, 
    this.size = 20, 
    this.borderRadius = 8
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}



