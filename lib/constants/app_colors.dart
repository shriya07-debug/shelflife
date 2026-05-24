import 'package:flutter/material.dart';

/// Centralized colors with light + dark variants.
/// Use AppColors.bg(context), AppColors.card(context), etc. so colors
/// switch automatically with the active theme.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary       = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF2E7D32);
  static const Color primaryDeeper = Color(0xFF1B5E20);
  static const Color primaryLight  = Color(0xFFE8F5E9);

  // Light theme
  static const Color lightBackground    = Color(0xFFF5F6FA);
  static const Color lightCard          = Colors.white;
  static const Color lightDivider       = Color(0xFFE5E7EB);
  static const Color lightTextPrimary   = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted     = Color(0xFF9CA3AF);
  static const Color lightChipBg        = Color(0xFFF3F4F6);
  static const Color lightChipUnselected= Color(0xFFE3F2FD);
  static const Color lightInputFill     = Colors.white;
  static const Color lightInfoBg        = Color(0xFFEFF6FF);

  // Dark theme
  static const Color darkBackground     = Color(0xFF121417);
  static const Color darkCard           = Color(0xFF1E2126);
  static const Color darkDivider        = Color(0xFF2D3138);
  static const Color darkTextPrimary    = Color(0xFFF3F4F6);
  static const Color darkTextSecondary  = Color(0xFFB0B4BA);
  static const Color darkTextMuted      = Color(0xFF6B7280);
  static const Color darkChipBg         = Color(0xFF262A30);
  static const Color darkChipUnselected = Color(0xFF1F2429);
  static const Color darkInputFill      = Color(0xFF1E2126);
  static const Color darkInfoBg         = Color(0xFF18242E);

  // Status
  static const Color warning      = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color danger       = Color(0xFFF44336);
  static const Color dangerLight  = Color(0xFFFFEBEE);
  static const Color safe         = Color(0xFF16A34A);
  static const Color safeLight    = Color(0xFFE8F5E9);

  // Social
  static const Color facebookBlue = Color(0xFF1877F2);

  // Context-aware helpers
  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c)        => _isDark(c) ? darkBackground   : lightBackground;
  static Color card(BuildContext c)      => _isDark(c) ? darkCard         : lightCard;
  static Color divider(BuildContext c)   => _isDark(c) ? darkDivider      : lightDivider;
  static Color textPri(BuildContext c)   => _isDark(c) ? darkTextPrimary  : lightTextPrimary;
  static Color textSec(BuildContext c)   => _isDark(c) ? darkTextSecondary: lightTextSecondary;
  static Color textMut(BuildContext c)   => _isDark(c) ? darkTextMuted    : lightTextMuted;
  static Color chipBg(BuildContext c)    => _isDark(c) ? darkChipBg       : lightChipBg;
  static Color infoBg(BuildContext c)    => _isDark(c) ? darkInfoBg       : lightInfoBg;
  static Color chipUnsel(BuildContext c) => _isDark(c) ? darkChipUnselected : lightChipUnselected;
}
