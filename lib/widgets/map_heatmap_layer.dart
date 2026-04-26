import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';

enum HeatmapMode { aqi, floodRisk }

class MapHeatmapLayer extends StatefulWidget {
  const MapHeatmapLayer({
    super.key,
    required this.mode,
  });

  final HeatmapMode mode;

  @override
  State<MapHeatmapLayer> createState() => _MapHeatmapLayerState();
}

class _MapHeatmapLayerState extends State<MapHeatmapLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aqi = context.watch<AqiProvider>();
    final flood = context.watch<FloodProvider>();
    final points = _buildPoints(widget.mode, aqi, flood);

    return Stack(
      children: [
        if (points.isEmpty)
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _NoHeatmapDataBanner(),
          ),
        CircleLayer(
          circles: points
              .map(
                (point) => CircleMarker(
                  point: point.location,
                  useRadiusInMeter: true,
                  radius: _radiusFor(point.value, widget.mode),
                  color: _colorFor(point.value, widget.mode).withOpacity(0.24),
                  borderStrokeWidth: 1.3,
                  borderColor:
                      _colorFor(point.value, widget.mode).withOpacity(0.62),
                ),
              )
              .toList(growable: false),
        ),
        MarkerLayer(
          markers: points
              .map(
                (point) => Marker(
                  point: point.location,
                  width: 86,
                  height: 86,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedCity =
                            _selectedCity == point.city ? null : point.city;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final isSelected = _selectedCity == point.city;
                        final pulse =
                            1 + (math.sin(_pulseController.value * math.pi) * 0.08);
                        return Center(
                          child: Transform.scale(
                            scale: isSelected ? pulse : 1,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _colorFor(point.value, widget.mode),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.2),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -42,
                                    child: _HeatmapTooltip(
                                      city: point.city,
                                      value: point.value,
                                      mode: widget.mode,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  List<_HeatmapPoint> _buildPoints(
      HeatmapMode mode, AqiProvider aqi, FloodProvider flood) {
    if (mode == HeatmapMode.aqi) {
      final dynamic dyn = aqi;
      List<dynamic>? raw;
      try {
        raw = (dyn.cityReadings as List?)?.cast<dynamic>();
      } catch (e) {
        debugPrint('[MapHeatmapLayer] Failed to read cityReadings: $e');
      }

      if (raw != null && raw.isNotEmpty) {
        final points = <_HeatmapPoint>[];
        for (final entry in raw) {
          try {
            points.add(
              _HeatmapPoint(
                city: entry.city as String,
                location: LatLng(
                  (entry.latitude as num).toDouble(),
                  (entry.longitude as num).toDouble(),
                ),
                value: (entry.aqi as num).toDouble(),
              ),
            );
          } catch (_) {
            debugPrint('[MapHeatmapLayer] Ignored malformed AQI heatmap entry.');
          }
        }
        if (points.isNotEmpty) return points;
      }
      return const [];
    }

    final dynamic dyn = flood;
    List<dynamic>? raw;
    try {
      raw = (dyn.cityRisks as List?)?.cast<dynamic>();
    } catch (e) {
      debugPrint('[MapHeatmapLayer] Failed to read cityRisks: $e');
    }

    if (raw != null && raw.isNotEmpty) {
      final points = <_HeatmapPoint>[];
      for (final entry in raw) {
        try {
          points.add(
            _HeatmapPoint(
              city: entry.city as String,
              location: LatLng(
                (entry.latitude as num).toDouble(),
                (entry.longitude as num).toDouble(),
              ),
              value: (entry.riskScore as num).toDouble(),
            ),
          );
        } catch (_) {
          debugPrint('[MapHeatmapLayer] Ignored malformed flood heatmap entry.');
        }
      }
      if (points.isNotEmpty) return points;
    }
    return const [];
  }

  Color _colorFor(double value, HeatmapMode mode) {
    if (mode == HeatmapMode.aqi) {
      if (value <= 50) return AppColors.success;
      if (value <= 100) return const Color(0xFFFFD54F);
      if (value <= 150) return const Color(0xFFFF9800);
      if (value <= 200) return const Color(0xFFE53935);
      return const Color(0xFF6D1B1B);
    }

    if (value <= 30) return AppColors.success;
    if (value <= 60) return const Color(0xFFFFD54F);
    if (value <= 80) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  double _radiusFor(double value, HeatmapMode mode) {
    if (mode == HeatmapMode.aqi) {
      return (9000 + (value.clamp(0, 300) / 300) * 23000).toDouble();
    }
    return (8000 + (value.clamp(0, 100) / 100) * 20000).toDouble();
  }
}

class _NoHeatmapDataBanner extends StatelessWidget {
  const _NoHeatmapDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'Live city heatmap data is unavailable right now.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _HeatmapPoint {
  const _HeatmapPoint({
    required this.city,
    required this.location,
    required this.value,
  });

  final String city;
  final LatLng location;
  final double value;
}

class _HeatmapTooltip extends StatelessWidget {
  const _HeatmapTooltip({
    required this.city,
    required this.value,
    required this.mode,
  });

  final String city;
  final double value;
  final HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final valueLabel = mode == HeatmapMode.aqi
        ? 'AQI ${value.round()}'
        : 'Risk ${value.round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.93),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        '$city • $valueLabel',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
