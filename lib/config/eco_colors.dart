import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Theme-aware color set. Use EcoColors.of(context) to get the right palette.
/// AppColors keeps the dark constants for screens not yet migrated.
class EcoColors {
  const EcoColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.bgElevated,
    required this.bgSurface,
    required this.borderSubtle,
    required this.border,
    required this.primary,
    required this.primaryDim,
    required this.primaryGlow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.critical,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textInverse,
    required this.isDark,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgCard;
  final Color bgElevated;
  final Color bgSurface;
  final Color borderSubtle;
  final Color border;
  final Color primary;
  final Color primaryDim;
  final Color primaryGlow;
  final Color success;
  final Color warning;
  final Color danger;
  final Color critical;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textInverse;
  final bool isDark;

  static EcoColors of(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return isDark ? dark : light;
  }

  // ── Dark palette ────────────────────────────────────────────────────────────
  static const dark = EcoColors(
    bgPrimary:    Color(0xFF000000),
    bgSecondary:  Color(0xFF0A0A0A),
    bgCard:       Color(0xFF0D0D0D),
    bgElevated:   Color(0xFF1A1A1A),
    bgSurface:    Color(0xFF000000),
    borderSubtle: Color(0x22FFFFFF),
    border:       Color(0x33FFFFFF),
    primary:      Color(0xFFAAAAAA),
    primaryDim:   Color(0xFF888888),
    primaryGlow:  Color(0x22AAAAAA),
    success:      Color(0xFF10D679),
    warning:      Color(0xFFFFAA55),
    danger:       Color(0xFFFF5555),
    critical:     Color(0xFFDC2626),
    info:         Color(0xFF818CF8),
    textPrimary:  Color(0xFFFFFFFF),
    textSecondary:Color(0x88FFFFFF),
    textDisabled: Color(0x55FFFFFF),
    textInverse:  Color(0xFF000000),
    isDark:       true,
  );

  // ── Light palette ───────────────────────────────────────────────────────────
  static const light = EcoColors(
    bgPrimary:    Color(0xFFF2F2F7),
    bgSecondary:  Color(0xFFE8E8EE),
    bgCard:       Color(0xFFFFFFFF),
    bgElevated:   Color(0xFFEEEEF3),
    bgSurface:    Color(0xFFFFFFFF),
    borderSubtle: Color(0x18000000),
    border:       Color(0x28000000),
    primary:      Color(0xFF2C2C2E),
    primaryDim:   Color(0xFF555558),
    primaryGlow:  Color(0x182C2C2E),
    success:      Color(0xFF0ABF63),
    warning:      Color(0xFFE8961E),
    danger:       Color(0xFFE03535),
    critical:     Color(0xFFBF1C1C),
    info:         Color(0xFF5B56D4),
    textPrimary:  Color(0xFF111111),
    textSecondary:Color(0x99000000),
    textDisabled: Color(0x66000000),
    textInverse:  Color(0xFFFFFFFF),
    isDark:       false,
  );
}
