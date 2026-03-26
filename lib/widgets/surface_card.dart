import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import 'app_card.dart';

/// Use for regular content cards — Deep Ocean design.
/// Wraps AppCard for backward compatibility.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.p16),
      onTap: onTap,
      child: child,
    );
  }
}
