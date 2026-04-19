import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/weather_model.dart';

Widget getWeatherIcon(int code) {
  switch (code) {
    case 0:
    case 1:
      return const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFB74D), size: 24);
    case 2:
      return const Icon(Icons.cloud_queue_rounded, color: AppColors.textPrimary, size: 24);
    case 3:
      return const Icon(Icons.cloud_rounded, color: AppColors.textPrimary, size: 24);
    case 45:
    case 48:
      return const Icon(Icons.foggy, color: AppColors.textSecondary, size: 24);
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return const Icon(Icons.grain_rounded, color: AppColors.primary, size: 24);
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
    case 80:
    case 81:
    case 82:
      return const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 24);
    case 71:
    case 73:
    case 75:
    case 77:
    case 85:
    case 86:
      return const Icon(Icons.ac_unit_rounded, color: Color(0xFFB3E5FC), size: 24);
    case 95:
    case 96:
    case 99:
      return const Icon(Icons.thunderstorm_rounded, color: AppColors.warning, size: 24);
    default:
      return const Icon(Icons.cloud_rounded, color: AppColors.textPrimary, size: 24);
  }
}

class WeatherForecastWidget extends StatelessWidget {
  const WeatherForecastWidget({
    super.key,
    required this.isLoading,
    required this.currentWeather,
    this.showCachedBadge = false,
  });

  final bool isLoading;
  final WeatherCondition? currentWeather;
  final bool showCachedBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3-Day Forecast',
          style: AppTextStyles.headline.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        Stack(
          children: [
            SizedBox(
              height: 152,
              child: isLoading
                  ? _buildLoadingStrip()
                  : currentWeather == null
                      ? _buildUnavailableState()
                      : _buildForecastStrip(currentWeather!),
            ),
            if (showCachedBadge)
              Positioned(
                top: 8,
                right: 8,
                child: _buildCachedBadge(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCachedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Text(
        'CACHED',
        style: AppTextStyles.label.copyWith(
          color: AppColors.warning,
          fontSize: 9,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildLoadingStrip() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p12),
      itemBuilder: (_, __) => Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radius12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Text(
          'Forecast unavailable',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildForecastStrip(WeatherCondition weather) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p12),
      itemBuilder: (_, index) {
        final label = _dayLabel(index);
        final low = weather.tempMin?.round() ?? weather.temperature.round();
        final high = weather.tempMax?.round() ?? weather.temperature.round();
        final rainProbability = _rainChanceFromCode(weather.weatherCode);

        return Container(
          width: 150,
          padding: const EdgeInsets.all(AppSpacing.p12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.titleMed.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.p8),
              getWeatherIcon(weather.weatherCode),
              const SizedBox(height: AppSpacing.p8),
              Text(
                '$high° / $low°C',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.p6),
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.p4),
                  Text(
                    '$rainProbability%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _dayLabel(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return 'Day after';
  }

  int _rainChanceFromCode(int code) {
    if (code == 0 || code == 1) return 5;
    if (code == 2 || code == 3) return 20;
    if (code == 45 || code == 48) return 25;
    if (code >= 51 && code <= 67) return 70;
    if (code >= 71 && code <= 86) return 55;
    if (code >= 95) return 80;
    return 30;
  }
}