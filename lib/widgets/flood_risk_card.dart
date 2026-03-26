import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/flood_model.dart';

/// Weather-style flood risk card — plain English, no technical score.
class FloodRiskCard extends StatelessWidget {
  const FloodRiskCard({
    super.key,
    required this.risk,
    this.onTap,
  });

  final FloodRisk risk;
  final VoidCallback? onTap;

  String get _plainEnglish {
    switch (risk.level) {
      case FloodRiskLevel.low:
        return 'No immediate flood risk today';
      case FloodRiskLevel.moderate:
        return 'Some rain expected today';
      case FloodRiskLevel.high:
        return 'Heavy rain — flood risk high';
      case FloodRiskLevel.critical:
        return 'Flooding likely — take action';
    }
  }

  List<Color> get _gradientColors {
    switch (risk.level) {
      case FloodRiskLevel.low:
        return [
          AppColors.bgCard,
          AppColors.success.withOpacity(0.15),
        ];
      case FloodRiskLevel.moderate:
        return [
          AppColors.bgCard,
          AppColors.warning.withOpacity(0.12),
        ];
      case FloodRiskLevel.high:
        return [
          AppColors.bgCard,
          AppColors.warning.withOpacity(0.2),
        ];
      case FloodRiskLevel.critical:
        return [
          AppColors.bgCard,
          AppColors.danger.withOpacity(0.2),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radius20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: risk.color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop, color: risk.color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'FLOOD RISK',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        risk.city.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p16),
                  Text(
                    risk.levelLabel.toUpperCase(),
                    style: AppTextStyles.displayMed.copyWith(
                      color: risk.color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p6),
                  Text(
                    _plainEnglish,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p12),
                  Row(
                    children: [
                      Icon(Icons.grain, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${risk.rainfall.mm24h.toStringAsFixed(0)}mm rain today',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Details →',
                        style: AppTextStyles.label.copyWith(
                          color: risk.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: risk.color.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radius20),
                  bottomRight: Radius.circular(AppSpacing.radius20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
