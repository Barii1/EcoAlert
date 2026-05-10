import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/weather_model.dart';

/// Minimal weather card with a black surface, outlined frame, and a low/high/current graph.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
  });

  final WeatherCondition weather;

  @override
  Widget build(BuildContext context) {
    final low = weather.tempMin ?? (weather.temperature - 2);
    final high = weather.tempMax ?? (weather.temperature + 2);
    final current = weather.temperature;
    final accent = _accentForWeather();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChipLabel(label: weather.city.toUpperCase()),
              _ChipLabel(label: 'NOW'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.round().toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 58,
                            height: 0.9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -3,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.55),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weather.description.toLowerCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'H:${high.round()}°  L:${low.round()}°',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Icon(
                  _weatherIcon(),
                  color: accent,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: _TemperatureGraph(
              low: low,
              high: high,
              current: current,
              accent: accent,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Feels like',
                  value: '${weather.feelsLike.round()}°',
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Humidity',
                  value: '${weather.humidity}%',
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Wind',
                  value: '${weather.windSpeed.round()} km/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _weatherIcon() {
    final hour = weather.timestamp.hour;
    final isNight = hour < 6 || hour >= 19;
    switch (weather.weatherCode) {
      case 0:
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

  Color _accentForWeather() {
    final code = weather.weatherCode;
    if (code == 0 || code == 1) return const Color(0xFFAAAAAA);
    if (code >= 61 && code <= 82) return const Color(0xFFAAAAAA);
    if (code >= 95) return const Color(0xFFAAAAAA);
    return const Color(0xFFB8B8B8);
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.3,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}

class _TemperatureGraph extends StatelessWidget {
  const _TemperatureGraph({
    required this.low,
    required this.high,
    required this.current,
    required this.accent,
  });

  final double low;
  final double high;
  final double current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final range = math.max(1.0, high - low);
    final currentPosition = ((current - low) / range).clamp(0.0, 1.0);
    final lowPosition = 0.0;
    final highPosition = 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GraphPainter(
                  accent: accent,
                  lowPosition: lowPosition,
                  currentPosition: currentPosition,
                  highPosition: highPosition,
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: _GraphCaption(label: 'LOW', value: low.round()),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _GraphCaption(label: 'HIGH', value: high.round()),
            ),
            Positioned(
              left: constraints.maxWidth * currentPosition - 18,
              top: 14,
              child: _CurrentMarker(value: current.round(), accent: accent),
            ),
          ],
        );
      },
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.accent,
    required this.lowPosition,
    required this.currentPosition,
    required this.highPosition,
  });

  final Color accent;
  final double lowPosition;
  final double currentPosition;
  final double highPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = accent.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final start = Offset(18, size.height * 0.70);
    final mid = Offset(size.width * currentPosition, size.height * 0.28);
    final end = Offset(size.width - 18, size.height * 0.55);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.72, size.width * 0.40, size.height * 0.48)
      ..quadraticBezierTo(size.width * 0.54, size.height * 0.18, mid.dx, mid.dy)
      ..quadraticBezierTo(size.width * 0.74, size.height * 0.14, end.dx, end.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width - 18, size.height - 8)
      ..lineTo(18, size.height - 8)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, accentPaint);
    canvas.drawLine(Offset(18, size.height * 0.82), Offset(size.width - 18, size.height * 0.82), linePaint);
    canvas.drawCircle(mid, 5.5, Paint()..color = Colors.black..style = PaintingStyle.fill);
    canvas.drawCircle(mid, 5.5, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.lowPosition != lowPosition ||
        oldDelegate.highPosition != highPosition;
  }
}

class _GraphCaption extends StatelessWidget {
  const _GraphCaption({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value°',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}

class _CurrentMarker extends StatelessWidget {
  const _CurrentMarker({required this.value, required this.accent});

  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Text(
        '$value°',
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
