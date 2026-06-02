import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../config/city_hazard_zones.dart';
import '../models/flood_model.dart';
import '../models/hazard_zone_model.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';

enum HeatmapMode { aqi, floodRisk }

class MapHeatmapLayer extends StatefulWidget {
  const MapHeatmapLayer({
    super.key,
    required this.mode,
    required this.zones,
  });

  final HeatmapMode mode;
  final List<HazardZoneModel> zones;

  @override
  State<MapHeatmapLayer> createState() => _MapHeatmapLayerState();
}

class _MapHeatmapLayerState extends State<MapHeatmapLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String? _selectedZone;

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
    final points = _buildPoints(widget.mode, widget.zones, aqi, flood);

    return Stack(
      children: [
        CircleLayer(
          circles: points
              .map(
                (point) => CircleMarker(
                  point: point.location,
                  useRadiusInMeter: true,
                  radius: _radiusFor(point.value, widget.mode),
                  color: _colorFor(point.value, widget.mode).withOpacity(0.28),
                  borderStrokeWidth: 2,
                  borderColor:
                      _colorFor(point.value, widget.mode).withOpacity(0.75),
                ),
              )
              .toList(growable: false),
        ),
        MarkerLayer(
          markers: points
              .map(
                (point) => Marker(
                  point: point.location,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedZone =
                            _selectedZone == point.label ? null : point.label;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final isSelected = _selectedZone == point.label;
                        final pulse = 1 +
                            (math.sin(_pulseController.value * math.pi) * 0.1);
                        return Center(
                          child: Transform.scale(
                            scale: isSelected ? pulse : 1,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _colorFor(point.value, widget.mode),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.85),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _colorFor(point.value, widget.mode)
                                                .withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -44,
                                    child: _HeatmapTooltip(
                                      label: point.label,
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
    HeatmapMode mode,
    List<HazardZoneModel> zones,
    AqiProvider aqi,
    FloodProvider flood,
  ) {
    final aqiOnly = mode == HeatmapMode.aqi;
    final cityAqi = aqi.current?.aqi ?? 50;
    final floodLevel = flood.risk?.level ?? FloodRiskLevel.low;
    final rainfall = flood.risk?.rainfall;

    return zones
        .where((z) => aqiOnly ? z.type == 'aqi' : z.type == 'flood')
        .map((z) {
      final value = aqiOnly
          ? _zoneAqi(z.name, cityAqi).toDouble()
          : _zoneFloodScore(z.name, floodLevel, rainfall);
      return _HeatmapPoint(
        label: z.name,
        location: LatLng(z.latitude, z.longitude),
        value: value,
      );
    }).toList(growable: false);
  }

  int _zoneAqi(String zoneName, int cityAqi) {
    return CityHazardZones.zoneAqi(zoneName, cityAqi);
  }

  double _zoneFloodScore(
    String zoneName,
    FloodRiskLevel level,
    RainfallData? rainfall,
  ) {
    return CityHazardZones.zoneFloodScore(
      zoneName,
      level,
      rainfall: rainfall,
    );
  }

  Color _colorFor(double value, HeatmapMode mode) {
    if (mode == HeatmapMode.aqi) {
      if (value <= 50) return AppColors.success;
      if (value <= 100) return const Color(0xFFFFD54F);
      if (value <= 150) return const Color(0xFFFF9800);
      if (value <= 200) return AppColors.danger;
      return const Color(0xFF6D1B1B);
    }

    if (value <= 30) return AppColors.success;
    if (value <= 60) return const Color(0xFFFFD54F);
    if (value <= 80) return AppColors.warning;
    return AppColors.danger;
  }

  double _radiusFor(double value, HeatmapMode mode) {
    if (mode == HeatmapMode.aqi) {
      return 450 + (value.clamp(0, 250) / 250) * 950;
    }
    return 450 + (value.clamp(0, 100) / 100) * 900;
  }
}

class _HeatmapPoint {
  const _HeatmapPoint({
    required this.label,
    required this.location,
    required this.value,
  });

  final String label;
  final LatLng location;
  final double value;
}

class _HeatmapTooltip extends StatelessWidget {
  const _HeatmapTooltip({
    required this.label,
    required this.value,
    required this.mode,
  });

  final String label;
  final double value;
  final HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final valueLabel = mode == HeatmapMode.aqi
        ? 'AQI ${value.round()}'
        : 'Risk ${value.round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        '$label • $valueLabel',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
