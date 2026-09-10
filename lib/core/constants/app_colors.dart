import 'package:flutter/material.dart';

/// App color palette derived directly from the "பரமனின் கீதங்கள்" splash cover:
/// - Deep Celestial Indigo (#201E38, #37466E)
/// - Radiant Sunrise Gold (#F6B071, #FDD993)
/// - Sacred Rose / Mauve (#C15063)
/// - Warm Ivory / Heavenly Parchment (#FBF9F4, #FFFFFF)
class AppColors {
  AppColors._();

  // Primary Celestial Hues
  static const Color primaryDark = Color(0xFF201E38);
  static const Color primary = Color(0xFF2E2C4D);
  static const Color primaryLight = Color(0xFF3E3B68);
  static const Color celestialBlue = Color(0xFF37466E);

  // Radiant Sunrise Accents
  static const Color sunriseGold = Color(0xFFF6B071);
  static const Color sunriseAmber = Color(0xFFEAA15A);
  static const Color amberGlow = Color(0xFFFDD993);
  static const Color sacredRose = Color(0xFFC15063);

  // Background & Surfaces
  static const Color scaffoldBackground = Color(0xFFF9F7F2);
  static const Color cardBackground = Colors.white;
  static const Color cardSubtle = Color(0xFFFFFBF5);
  static const Color cardBorder = Color(0xFFEAE3D6);
  static const Color dividerColor = Color(0xFFE6DFC5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1B29);
  static const Color textSecondary = Color(0xFF6B677A);
  static const Color textMuted = Color(0xFF9C98A6);
  static const Color textOnPrimary = Colors.white;

  // Accents & Badges
  static const Color favoriteRed = Color(0xFFE53935);
  static const Color favoriteBadge = Color(0xFFFF5252);
  static const Color activeNav = Color(0xFFF6B071);
  static const Color inactiveNav = Color(0xFFA5A0B3);
}
