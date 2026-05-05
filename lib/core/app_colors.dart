import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Emerald & Forest (Mainly for City Agri)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color emeraldPrimary = primary;
  static const Color primaryDark = Color(0xFF064E3B); // Emerald 900
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryAccent = Color(0xFF10B981); // Emerald 500

  static const Color secondary = Color(0xFF0F172A); // Slate 900 (Professional Sidebar)
  static const Color tertiary = Color(0xFF6366F1); // Indigo 500
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color goldAccent = Color(0xFFFFD700); // Gold
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color surface = Colors.white;
  
  // Text
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );

  // Glassmorphism Base
  static Color glassBase = Colors.white.withValues(alpha: 0.7);
  static Color glassBorder = Colors.white.withValues(alpha: 0.3);

  // Premium Dark Theme Colors
  static const Color premiumDarkBackground = Color(0xFF0F172A);
  static const Color premiumNavy = Color(0xFF0B121E);
  static const Color premiumCard = Color(0xFF1E293B);
  static const Color premiumEmerald = Color(0xFF10B981);
}

class Slate {
  static const Color shade50 = Color(0xFFF8FAFC);
  static const Color shade100 = Color(0xFFF1F5F9);
  static const Color shade200 = Color(0xFFE2E8F0);
  static const Color shade300 = Color(0xFFCBD5E1);
  static const Color shade400 = Color(0xFF94A3B8);
  static const Color shade500 = Color(0xFF64748B);
  static const Color shade600 = Color(0xFF475569);
  static const Color shade700 = Color(0xFF334155);
  static const Color shade800 = Color(0xFF1E293B);
  static const Color shade900 = Color(0xFF0F172A);
  static const Color shade950 = Color(0xFF020617);
}


