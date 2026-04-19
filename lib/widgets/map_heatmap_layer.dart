import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/city_mappings.dart';
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
    // TODO(Bari): Expose a multi-city collection from providers (for example
    // `cityReadings` / `cityRisks`) including city, latitude, longitude and
    // value. The current providers only expose one active city reading.

    if (mode == HeatmapMode.aqi) {
      final dynamic dyn = aqi;
      List<dynamic>? raw;
      try {
        raw = (dyn.cityReadings as List?)?.cast<dynamic>();
      } catch (_) {}

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
            // Ignore malformed entry and continue rendering available points.
          }
        }
        if (points.isNotEmpty) return points;
      }

      final base = (aqi.current?.aqi ?? 88).toDouble();
      return _buildFallbackPoints(
        baseValue: base,
        clampMin: 15,
        clampMax: 320,
        deltas: const [-28, -12, 0, 14, 32, -5, 20, 6],
      );
    }

    final dynamic dyn = flood;
    List<dynamic>? raw;
    try {
      raw = (dyn.cityRisks as List?)?.cast<dynamic>();
    } catch (_) {}

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
          // Ignore malformed entry and continue rendering available points.
        }
      }
      if (points.isNotEmpty) return points;
    }

    final base = (flood.risk?.riskScore ?? 44).toDouble();
    return _buildFallbackPoints(
      baseValue: base,
      clampMin: 0,
      clampMax: 100,
      deltas: const [-18, -10, 0, 9, 18, -6, 13, 4],
    );
  }

  List<_HeatmapPoint> _buildFallbackPoints({
    required double baseValue,
    required double clampMin,
    required double clampMax,
    required List<int> deltas,
  }) {
    final entries = CityMappings.cityCoords.entries.toList(growable: false);
    final result = <_HeatmapPoint>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final coords = entry.value;
      final value = (baseValue + deltas[i % deltas.length])
          .clamp(clampMin, clampMax)
          .toDouble();
      result.add(
        _HeatmapPoint(
          city: entry.key,
          location: LatLng(coords[0], coords[1]),
          value: value,
        ),
      );
    }

    return result;
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
