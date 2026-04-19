import 'package:flutter/material.dart';
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
      padding: padding ?? const EdgeInsets.all(16),
      onTap: onTap,
      child: child,
    );
  }
}
