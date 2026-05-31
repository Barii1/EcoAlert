import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aqi_model.dart';
import '../providers/aqi_provider.dart';
import '../widgets/aqi_gauge.dart';
import '../widgets/share_card_widget.dart';
import '../widgets/surface_card.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class AqiDetailScreen extends StatefulWidget {
  const AqiDetailScreen({super.key});

  @override
  State<AqiDetailScreen> createState() => _AqiDetailScreenState();
}

class _AqiDetailScreenState extends State<AqiDetailScreen> {
  final _shareKey = GlobalKey();

  // ── Share logic ────────────────────────────────────────────────────────────

  Future<void> _share() async {
    try {
      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final file = File('${Directory.systemTemp.path}/ecoalert_aqi_share.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Air quality report from EcoAlert',
      );
    } catch (e) {
      debugPrint('[EcoAlert] AQI share error: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    AqiReading? reading;
    if (args is AqiReading) {
      reading = args;
    } else {
      reading = context.read<AqiProvider>().current;
    }

    if (reading == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Air Quality')),
        body: const Center(child: Text('No AQI data')),
      );
    }

    final hourly = context.watch<AqiProvider>().hourly;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: const Text('Air Quality'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _share,
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main scrollable content ────────────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reading.city,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
                      style: AppTextStyles.headline.copyWith(
                        color: reading.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SurfaceCard(
                    child: Row(
                      children: [
                        Icon(Icons.health_and_safety,
                            color: reading.color, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reading.healthAdvice,
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRiskChips(),
                  const SizedBox(height: 16),
                  _buildPollutantsCard(reading),
                  if (hourly.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTrendChart(hourly),
                  ],
                  const SizedBox(height: 16),
                  _buildPrecautionsList(reading),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Share card rendered off-screen ─────────────────────────────
          Positioned(
            left: -3000,
            top: 0,
            child: ShareCardWidget(
              repaintKey: _shareKey,
              city: reading.city,
              metricLabel: 'AQI',
              value: reading.aqi.toString(),
              valueLabel: reading.categoryLabel,
              accentColor: reading.color,
              timestamp: reading.timestamp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Existing helpers (unchanged) ───────────────────────────────────────────

  Widget _buildRiskChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _riskChip('Children', Icons.child_care, AppColors.danger),
        _riskChip('Elderly', Icons.elderly, AppColors.danger),
        _riskChip('Outdoor Workers', Icons.construction, AppColors.danger),
      ],
    );
  }

  Widget _riskChip(String label, IconData icon, Color color) {
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
          Text(label, style: AppTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildPollutantsCard(AqiReading reading) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pollutants',
              style: AppTextStyles.titleMed
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _pollutantRow('PM2.5', reading.pm25, 'µg/m³',
              reading.aqi / 500),
          _pollutantRow('PM10', reading.pm10, 'µg/m³',
              (reading.pm10 / 200).clamp(0.0, 1.0)),
          _pollutantRow('O₃', reading.o3, 'ppb',
              (reading.o3 / 100).clamp(0.0, 1.0)),
          _pollutantRow('NO₂', reading.no2, 'ppb',
              (reading.no2 / 100).clamp(0.0, 1.0)),
          _pollutantRow('CO', reading.co, 'ppm',
              (reading.co / 10).clamp(0.0, 1.0)),
        ],
      ),
    );
  }

  Widget _pollutantRow(
      String name, double value, String unit, double barValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text(name, style: AppTextStyles.bodySmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                backgroundColor: AppColors.bgCard,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<HourlyAqiPoint> hourly) {
    final spots = <FlSpot>[];
    for (var i = 0; i < hourly.length; i++) {
      spots.add(FlSpot(i.toDouble(), hourly[i].aqi.toDouble()));
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('24h AQI Trend',
              style: AppTextStyles.titleMed
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                    show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary
                              .withOpacity(0.5),
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
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary
                                  .withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
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
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecautionsList(AqiReading reading) {
    final bullets = <String>[];
    switch (reading.category) {
      case AqiCategory.good:
        bullets.addAll(
            ['Enjoy outdoor activities', 'Ventilate indoor spaces']);
        break;
      case AqiCategory.moderate:
        bullets.addAll([
          'Sensitive people: limit prolonged outdoor exertion',
          'Close windows if near traffic',
        ]);
        break;
      case AqiCategory.sensitive:
        bullets.addAll([
          'Reduce outdoor exercise',
          'People with asthma: keep rescue inhaler handy',
        ]);
        break;
      case AqiCategory.unhealthy:
        bullets.addAll([
          'Wear N95 mask outdoors',
          'Avoid strenuous activity',
          'Keep windows closed',
        ]);
        break;
      case AqiCategory.veryUnhealthy:
        bullets.addAll([
          'Stay indoors',
          'Use air purifier',
          'Reschedule outdoor events',
        ]);
        break;
      case AqiCategory.hazardous:
        bullets.addAll([
          'Health emergency',
          'Stay indoors',
          'Seek medical help if symptoms',
        ]);
        break;
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Precautions',
              style: AppTextStyles.titleMed
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: AppTextStyles.body),
                    Expanded(
                        child: Text(b, style: AppTextStyles.body)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
