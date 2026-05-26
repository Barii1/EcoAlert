import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Solid black background for dark minimal design.
/// Use with Scaffold(backgroundColor: Colors.transparent, body: AppBackground(child: ...)).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
      ),
      child: child,
    );
  }
}
