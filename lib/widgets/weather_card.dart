import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/weather_model.dart';

/// Premium weather widget card — inspired by iPhone/Samsung weather widgets.
/// Shows temperature, conditions, feels like, humidity, wind in a clean layout.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
  });

  final WeatherCondition weather;

  IconData _getWeatherIcon() {
    final hour = weather.timestamp.hour;
    final isNight = hour < 6 || hour >= 19;

    switch (weather.weatherCode) {
      case 0:
        return isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded;
      case 1:
        return isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded;
      case 2:
        return Icons.cloud_queue_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  Color _getWeatherAccent() {
    final code = weather.weatherCode;
    if (code == 0 || code == 1) return const Color(0xFFFFB74D); // sunny warm
    if (code == 2 || code == 3) return AppColors.textSecondary;
    if (code >= 45 && code <= 48) return const Color(0xFF90A4AE); // fog
    if (code >= 51 && code <= 67) return AppColors.primary; // rain
    if (code >= 71 && code <= 86) return const Color(0xFFB3E5FC); // snow
    if (code >= 95) return AppColors.warning; // thunderstorm
    return AppColors.textSecondary;
  }

  List<Color> _getGradient() {
    final code = weather.weatherCode;
    if (code == 0 || code == 1) {
      final hour = weather.timestamp.hour;
      if (hour < 6 || hour >= 19) {
        return [const Color(0xFF0D1B2A), const Color(0xFF1B2838)];
      }
      return [const Color(0xFF1A2640), const Color(0xFF2A3A55)];
    }
    if (code >= 61 || code >= 80) {
      return [AppColors.bgCard, AppColors.primary.withOpacity(0.08)];
    }
    return [AppColors.bgCard, AppColors.bgElevated];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getWeatherAccent();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradient(),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: city + weather label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    weather.city.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                'NOW',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.p16),

          // Main: big temperature + icon + description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temperature
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.description,
                      style: AppTextStyles.titleMed.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (weather.tempMin != null && weather.tempMax != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'H:${weather.tempMax!.round()}°  L:${weather.tempMin!.round()}°',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Weather icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(),
                  color: accent,
                  size: 36,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.p16),

          // Divider
          Container(
            height: 1,
            color: AppColors.borderSubtle,
          ),

          const SizedBox(height: AppSpacing.p12),

          // Details row: Feels Like, Humidity, Wind
          Row(
            children: [
              _DetailItem(
                icon: Icons.thermostat_rounded,
                label: 'Feels like',
                value: '${weather.feelsLike.round()}°',
              ),
              _divider(),
              _DetailItem(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weather.humidity}%',
              ),
              _divider(),
              _DetailItem(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '${weather.windSpeed.round()} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.borderSubtle,
      );
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMed.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
