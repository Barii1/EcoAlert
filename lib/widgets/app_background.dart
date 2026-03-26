import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Reusable gradient background — darker at top, lighter at bottom.
/// Use with Scaffold(backgroundColor: Colors.transparent, body: AppBackground(child: ...)).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgSecondary,
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: child,
    );
  }
}
