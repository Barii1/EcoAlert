import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/aqi_model.dart';

/// Home-page AQI card.
///
/// The home card highlights the project model's AQI score when available.
/// The detail page still receives the original reading and displays live US AQI.
class AqiCard extends StatelessWidget {
  const AqiCard({
    super.key,
    required this.reading,
    this.onTap,
  });

  final AqiReading reading;
  final VoidCallback? onTap;

  int get _displayAqi => reading.predictedAqi ?? reading.aqi;

  AqiCategory get _displayCategory =>
      reading.predictedCategory ?? reading.category;

  String get _displayCategoryLabel => _categoryLabel(_displayCategory);

  Color get _displayColor => _colorForCategory(_displayCategory);

  String get _plainEnglish {
    switch (_displayCategory) {
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
        return 'Health emergency - stay inside';
    }
  }

  IconData get _icon {
    switch (_displayCategory) {
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
    switch (_displayCategory) {
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
              color: _displayColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_icon, color: _displayColor, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'ECOALERT AQI',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          reading.city.split(' ').first.toUpperCase(),
                          style: TextStyle(
                            color: _displayColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
                            _displayCategoryLabel.toUpperCase(),
                            style: AppTextStyles.displayMed.copyWith(
                              color: _displayColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Text(
                          '$_displayAqi',
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
                          'Model score  ',
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
                                      ? _displayColor
                                      : AppColors.borderSubtle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Live data ->',
                          style: AppTextStyles.label.copyWith(
                            color: _displayColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _displayColor.withOpacity(0.6),
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
    if (_displayAqi <= 50) return 1;
    if (_displayAqi <= 100) return 2;
    if (_displayAqi <= 150) return 3;
    if (_displayAqi <= 200) return 4;
    if (_displayAqi <= 300) return 5;
    return 6;
  }

  Color _colorForCategory(AqiCategory category) {
    switch (category) {
      case AqiCategory.good:
        return const Color(0xFF00C853);
      case AqiCategory.moderate:
        return const Color(0xFFFFD600);
      case AqiCategory.sensitive:
        return const Color(0xFFFF6D00);
      case AqiCategory.unhealthy:
        return const Color(0xFFD50000);
      case AqiCategory.veryUnhealthy:
        return const Color(0xFF8E24AA);
      case AqiCategory.hazardous:
        return const Color(0xFF4A0000);
    }
  }

  String _categoryLabel(AqiCategory category) {
    switch (category) {
      case AqiCategory.good:
        return 'Good';
      case AqiCategory.moderate:
        return 'Moderate';
      case AqiCategory.sensitive:
        return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy:
        return 'Unhealthy';
      case AqiCategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiCategory.hazardous:
        return 'Hazardous';
    }
  }
}
