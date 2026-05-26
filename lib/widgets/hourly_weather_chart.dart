import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../models/weather_model.dart';

class HourlyWeatherChart extends StatelessWidget {
  const HourlyWeatherChart({super.key, required this.points});

  final List<HourlyWeatherPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    // Show next 24 hours from now (or all available if fewer).
    final now = DateTime.now();
    final upcoming = points
        .where((p) => p.time.isAfter(now.subtract(const Duration(minutes: 30))))
        .take(24)
        .toList();

    if (upcoming.isEmpty) return const SizedBox.shrink();

    final temps = upcoming.map((p) => p.temperature).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final tempRange = (maxTemp - minTemp).clamp(4.0, double.infinity);
    final yMin = (minTemp - 2).floorToDouble();
    final yMax = (maxTemp + 2).ceilToDouble();

    final spots = <FlSpot>[
      for (var i = 0; i < upcoming.length; i++)
        FlSpot(i.toDouble(), upcoming[i].temperature),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Temperature',
          style: AppTextStyles.headline.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 12),
          child: LineChart(
            LineChartData(
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: tempRange > 8 ? 4 : 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderSubtle.withOpacity(0.5),
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: tempRange > 8 ? 4 : 2,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '${value.toInt()}°',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: upcoming.length <= 12 ? 2 : 4,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= upcoming.length) {
                        return const SizedBox.shrink();
                      }
                      final t = upcoming[idx].time;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('ha').format(t).toLowerCase(),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final isNow = (spot.x.toInt() == 0);
                      return FlDotCirclePainter(
                        radius: isNow ? 4 : 2,
                        color: isNow ? AppColors.primary : AppColors.primaryDim,
                        strokeWidth: isNow ? 2 : 0,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.18),
                        AppColors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.spotIndex;
                    if (idx >= upcoming.length) return null;
                    final p = upcoming[idx];
                    return LineTooltipItem(
                      '${DateFormat('ha').format(p.time).toLowerCase()}\n${p.temperature.toStringAsFixed(1)}°C',
                      AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
