import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';

/// Use for hero stats (AQI number, flood %) — brand gradient background.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDim],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
