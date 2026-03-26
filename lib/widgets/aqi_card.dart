import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/aqi_model.dart';

/// Weather-style AQI card — plain English, category-first.
class AqiCard extends StatelessWidget {
  const AqiCard({
    super.key,
    required this.reading,
    this.onTap,
  });

  final AqiReading reading;
  final VoidCallback? onTap;

  String get _plainEnglish {
    switch (reading.category) {
      case AqiCategory.good:
        return 'Great day to be outside';
      case AqiCategory.moderate:
        return 'Sensitive groups stay cautious';
      case AqiCategory.sensitive:
        return 'Limit outdoor time today';
      case AqiCategory.unhealthy:
        return 'Avoid outdoor activity today';
      case AqiCategory.veryUnhealthy:
        return 'Stay indoors, keep windows shut';
      case AqiCategory.hazardous:
        return 'Health emergency — stay inside';
    }
  }

  IconData get _icon {
    switch (reading.category) {
      case AqiCategory.good:
        return Icons.wb_sunny;
      case AqiCategory.moderate:
        return Icons.cloud;
      case AqiCategory.sensitive:
        return Icons.cloud_queue;
      case AqiCategory.unhealthy:
        return Icons.air;
      case AqiCategory.veryUnhealthy:
        return Icons.masks;
      case AqiCategory.hazardous:
        return Icons.warning_rounded;
    }
  }

  List<Color> get _gradientColors {
    switch (reading.category) {
      case AqiCategory.good:
      case AqiCategory.moderate:
        return [
          AppColors.bgCard,
          AppColors.primary.withOpacity(0.15),
        ];
      case AqiCategory.sensitive:
        return [
          AppColors.bgCard,
          AppColors.warning.withOpacity(0.12),
        ];
      case AqiCategory.unhealthy:
        return [
          AppColors.bgCard,
          AppColors.danger.withOpacity(0.12),
        ];
      case AqiCategory.veryUnhealthy:
      case AqiCategory.hazardous:
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
              color: reading.color.withOpacity(0.15),
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
                          Icon(_icon, color: reading.color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AIR QUALITY',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        reading.city.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          reading.categoryLabel.toUpperCase(),
                          style: AppTextStyles.displayMed.copyWith(
                            color: reading.color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${reading.aqi}',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                      Text(
                        'PM2.5  PM10  ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            6,
                            (i) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _aqiSegment
                                    ? reading.color
                                    : AppColors.borderSubtle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Details →',
                        style: AppTextStyles.label.copyWith(
                          color: reading.color,
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
                color: reading.color.withOpacity(0.6),
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

  int get _aqiSegment {
    if (reading.aqi <= 50) return 1;
    if (reading.aqi <= 100) return 2;
    if (reading.aqi <= 150) return 3;
    if (reading.aqi <= 200) return 4;
    if (reading.aqi <= 300) return 5;
    return 6;
  }
}
