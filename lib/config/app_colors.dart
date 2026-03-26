import 'package:flutter/material.dart';

/// Deep Ocean design system — centralized color palette.
/// All screens must use these colors; no inline hex codes.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFF070C14); // deepest — almost-black navy
  static const Color bgSecondary = Color(0xFF0E1521); // screen backgrounds
  static const Color bgCard = Color(0xFF141E2E); // standard cards
  static const Color bgElevated = Color(0xFF1A2640); // elevated / hover
  static const Color bgSurface = Color(0xFF0A0F1A); // drawer, overlays

  // Borders
  static const Color borderSubtle = Color(0xFF1E2D42); // subtle dividers
  static const Color border = Color(0xFF253449); // visible borders

  // Brand / Primary — Electric Cyan-Blue
  static const Color primary = Color(0xFF06C8FF); // main CTA, active states
  static const Color primaryDim = Color(0xFF0899C2); // gradients, pressed
  static const Color primaryGlow = Color(0x2006C8FF); // glow/shadow (12% opacity)

  // Semantic
  static const Color success = Color(0xFF10D679); // safe, good AQI, low risk
  static const Color warning = Color(0xFFFF8C00); // caution, moderate
  static const Color danger = Color(0xFFFF3B3B); // high risk, critical alerts
  static const Color critical = Color(0xFFDC2626); // critical emergency
  static const Color info = Color(0xFF818CF8); // informational, premium

  // Text
  static const Color textPrimary = Color(0xFFE8F4FE); // main text (off-white, blue tint)
  static const Color textSecondary = Color(0xFF7A9BB5); // labels, captions
  static const Color textDisabled = Color(0xFF3D5470); // disabled states
  static const Color textInverse = Color(0xFF070C14); // text on bright backgrounds
}
