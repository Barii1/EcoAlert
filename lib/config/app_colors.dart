import 'package:flutter/material.dart';

/// Dark minimal design system — centralized color palette.
/// All screens use pure black backgrounds, gray accents, and low-opacity white text.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFF000000); // pure black
  static const Color bgSecondary = Color(0xFF0A0A0A); // pure black variant
  static const Color bgCard = Color(0xFF0D0D0D); // card backgrounds
  static const Color bgElevated = Color(0xFF1A1A1A); // elevated / hover
  static const Color bgSurface = Color(0xFF000000); // drawer, overlays

  // Borders
  static const Color borderSubtle = Color(0x22FFFFFF); // subtle dividers (low opacity)
  static const Color border = Color(0x33FFFFFF); // visible borders (low opacity)

  // Brand / Primary — Gray Accent
  static const Color primary = Color(0xFFAAAAAA); // main CTA, active states
  static const Color primaryDim = Color(0xFF888888); // gradients, pressed
  static const Color primaryGlow = Color(0x22AAAAAA); // glow/shadow (low opacity)

  // Semantic
  static const Color success = Color(0xFF10D679); // safe, good AQI, low risk
  static const Color warning = Color(0xFFFFAA55); // caution, moderate (warm)
  static const Color danger = Color(0xFFFF5555); // high risk, critical alerts (red)
  static const Color critical = Color(0xFFDC2626); // critical emergency
  static const Color info = Color(0xFF818CF8); // informational, premium

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF); // main text (white)
  static const Color textSecondary = Color(0x88FFFFFF); // labels, captions (medium opacity)
  static const Color textDisabled = Color(0x55FFFFFF); // disabled states (low opacity)
  static const Color textInverse = Color(0xFF000000); // text on bright backgrounds
}
