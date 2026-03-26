import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/aqi_model.dart';
import '../providers/aqi_provider.dart';
import '../widgets/aqi_gauge.dart';
import '../widgets/surface_card.dart';

class AqiDetailScreen extends StatelessWidget {
  const AqiDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    AqiReading? reading;
    if (args is AqiReading) {
      reading = args;
    } else {
      final provider = context.read<AqiProvider>();
      reading = provider.current;
    }
    if (reading == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Air Quality')),
        body: const Center(child: Text('No AQI data')),
      );
    }
    final hourly = context.watch<AqiProvider>().hourly;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Air Quality'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reading.city,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            Center(
              child: AqiGauge(
                aqi: reading.aqi,
                color: reading.color,
                size: 180,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                reading.categoryLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: reading.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: reading.color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reading.healthAdvice,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildRiskChips(context),
            const SizedBox(height: 16),
            _buildPollutantsCard(context, reading),
            if (hourly.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTrendChart(context, hourly),
            ],
            const SizedBox(height: 16),
            _buildPrecautionsList(context, reading),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskChips(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _riskChip(context, 'Children', Icons.child_care, colors.error),
        _riskChip(context, 'Elderly', Icons.elderly, colors.error),
        _riskChip(context, 'Outdoor Workers', Icons.construction, colors.error),
      ],
    );
  }

  Widget _riskChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildPollutantsCard(BuildContext context, AqiReading reading) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pollutants',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _pollutantRow(context, 'PM2.5', reading.pm25, 'µg/m³', reading.aqi / 500),
          _pollutantRow(context, 'PM10', reading.pm10, 'µg/m³', (reading.pm10 / 200).clamp(0.0, 1.0)),
          _pollutantRow(context, 'O₃', reading.o3, 'ppb', (reading.o3 / 100).clamp(0.0, 1.0)),
          _pollutantRow(context, 'NO₂', reading.no2, 'ppb', (reading.no2 / 100).clamp(0.0, 1.0)),
          _pollutantRow(context, 'CO', reading.co, 'ppm', (reading.co / 10).clamp(0.0, 1.0)),
        ],
      ),
    );
  }

  Widget _pollutantRow(BuildContext context, String name, double value, String unit, double barValue) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(name, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${value.toStringAsFixed(1)} $unit', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<HourlyAqiPoint> hourly) {
    final spots = <FlSpot>[];
    for (var i = 0; i < hourly.length; i++) {
      spots.add(FlSpot(i.toDouble(), hourly[i].aqi.toDouble()));
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '24h AQI Trend',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: hourly.length > 12 ? 4 : 2,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= hourly.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH').format(hourly[i].hour),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Unhealthy threshold: 100',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecautionsList(BuildContext context, AqiReading reading) {
    final bullets = <String>[];
    switch (reading.category) {
      case AqiCategory.good:
        bullets.addAll(['Enjoy outdoor activities', 'Ventilate indoor spaces']);
        break;
      case AqiCategory.moderate:
        bullets.addAll(['Sensitive people: limit prolonged outdoor exertion', 'Close windows if near traffic']);
        break;
      case AqiCategory.sensitive:
        bullets.addAll(['Reduce outdoor exercise', 'People with asthma: keep rescue inhaler handy']);
        break;
      case AqiCategory.unhealthy:
        bullets.addAll(['Wear N95 mask outdoors', 'Avoid strenuous activity', 'Keep windows closed']);
        break;
      case AqiCategory.veryUnhealthy:
        bullets.addAll(['Stay indoors', 'Use air purifier', 'Reschedule outdoor events']);
        break;
      case AqiCategory.hazardous:
        bullets.addAll(['Health emergency', 'Stay indoors', 'Seek medical help if symptoms']);
        break;
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precautions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                    Expanded(child: Text(b, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
