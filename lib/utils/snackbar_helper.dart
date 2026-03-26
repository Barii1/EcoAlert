import 'package:flutter/material.dart';
import '../config/app_colors.dart';

void showComingSoon(BuildContext context, [String? feature]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(feature != null ? '$feature coming soon' : 'Coming soon'),
      backgroundColor: AppColors.bgElevated,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
