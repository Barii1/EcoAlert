import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: (color ?? AppColors.primary).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.2),
          Text(
            'EcoAlert',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
