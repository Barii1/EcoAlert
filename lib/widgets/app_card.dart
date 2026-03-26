import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';

/// Standard surface card with subtle border + shadow.
/// Replaces all Container(color: #162e2e) patterns.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Gradient accent card for hero sections (AQI hero, flood hero).
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final List<Color>? gradientColors;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [AppColors.primary, AppColors.primaryDim];

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
