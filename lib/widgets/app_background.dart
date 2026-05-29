import 'package:flutter/material.dart';
import '../config/eco_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EcoColors.of(context).bgPrimary,
      child: child,
    );
  }
}
