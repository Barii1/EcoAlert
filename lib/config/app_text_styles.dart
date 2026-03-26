import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Deep Ocean design system — typography scale.
/// All text must use these styles; no inline TextStyle with hardcoded sizes.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heroNumber =
      TextStyle(fontSize: 72, fontWeight: FontWeight.w700, letterSpacing: -2.0);
  static const TextStyle displayLarge =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const TextStyle displayMed =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
  static const TextStyle headline =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle titleLarge =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const TextStyle titleMed =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
  static const TextStyle body =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySmall =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle label =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8);

  /// Primary text color
  static TextStyle heroNumberPrimary =
      heroNumber.copyWith(color: AppColors.textPrimary);
  static TextStyle displayLargePrimary =
      displayLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle displayMedPrimary =
      displayMed.copyWith(color: AppColors.textPrimary);
  static TextStyle headlinePrimary =
      headline.copyWith(color: AppColors.textPrimary);
  static TextStyle titleLargePrimary =
      titleLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle titleMedPrimary =
      titleMed.copyWith(color: AppColors.textPrimary);
  static TextStyle bodyPrimary = body.copyWith(color: AppColors.textPrimary);
  static TextStyle bodySmallPrimary =
      bodySmall.copyWith(color: AppColors.textPrimary);
  static TextStyle labelPrimary = label.copyWith(color: AppColors.textPrimary);

  /// Secondary (dimmed) text color
  static TextStyle bodySecondary =
      body.copyWith(color: AppColors.textSecondary);
  static TextStyle bodySmallSecondary =
      bodySmall.copyWith(color: AppColors.textSecondary);
  static TextStyle labelSecondary =
      label.copyWith(color: AppColors.textSecondary);
}
