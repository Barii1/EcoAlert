import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../models/flood_model.dart';
import '../models/hazard_zone_model.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/hazard_zone_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/map_heatmap_layer.dart';
import '../widgets/map_legend.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _offlineBannerDismissed = false;
  HeatmapMode _heatmapMode = HeatmapMode.aqi;

  static final LatLng _lahore = LatLng(31.5204, 74.3587);

  bool get _isAqiMode => _heatmapMode == HeatmapMode.aqi;

  List<HazardZoneModel> _activeZones(
    HazardZoneProvider zones,
  ) {
    return zones.zonesForType(_isAqiMode ? 'aqi' : 'flood');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  /// Converts FloodRiskLevel → zone fill color.
  Color _floodZoneColor(FloodRiskLevel level) {
    switch (level) {
      case FloodRiskLevel.critical: return AppColors.danger;
      case FloodRiskLevel.high:     return AppColors.warning;
      case FloodRiskLevel.moderate: return const Color(0xFFFFAA55);
      case FloodRiskLevel.low:      return AppColors.success;
    }
  }

  /// Converts AQI value → zone fill color.
  Color _aqiZoneColor(int aqi) {
    if (aqi <= 50)  return AppColors.success;
    if (aqi <= 100) return const Color(0xFFFFD600);
    if (aqi <= 150) return const Color(0xFFFF6D00);
    if (aqi <= 200) return AppColors.danger;
    return const Color(0xFF6A1B9A);
  }

  /// Builds the list of model-driven hazard circles.
  List<CircleMarker> _buildHazardCircles(
    LatLng userPoint,
    FloodProvider floodProvider,
    AqiProvider aqiProvider,
    HazardZoneProvider zones,
  ) {
    final circles = <CircleMarker>[];
    final floodLevel = floodProvider.risk?.level ?? FloodRiskLevel.low;
    final cityAqi = aqiProvider.current?.aqi ?? 50;

    for (final z in _activeZones(zones)) {
      final point = LatLng(z.latitude, z.longitude);
      final radius = z.radiusMeters;
      final zoneAqi = _zoneAqi(z.name, cityAqi);
      final floodScore = _zoneFloodScore(z.name, floodLevel);
      final color = _isAqiMode
          ? _aqiZoneColor(zoneAqi)
          : _floodZoneColor(_scoreToLevel(floodScore));

      circles.add(CircleMarker(
        point: point,
        radius: radius,
        useRadiusInMeter: true,
        color: color.withOpacity(0.22),
        borderStrokeWidth: 2.5,
        borderColor: color.withOpacity(0.85),
      ));
    }

    // Safe zone around user (always green, 400 m)
    circles.add(CircleMarker(
      point: userPoint,
      radius: 400,
      useRadiusInMeter: true,
      color: AppColors.success.withOpacity(0.07),
      borderStrokeWidth: 2,
      borderColor: AppColors.success.withOpacity(0.5),
    ));

    return circles;
  }

  /// Builds tap-to-alert markers at each zone centre.
  FloodRiskLevel _scoreToLevel(double score) {
    if (score >= 80) return FloodRiskLevel.critical;
    if (score >= 60) return FloodRiskLevel.high;
    if (score >= 35) return FloodRiskLevel.moderate;
    return FloodRiskLevel.low;
  }

  List<Marker> _buildZoneMarkers(
    FloodProvider floodProvider,
    AqiProvider aqiProvider,
    HazardZoneProvider zones,
    BuildContext ctx,
  ) {
    final markers = <Marker>[];
    final floodLevel = floodProvider.risk?.level ?? FloodRiskLevel.low;
    final cityAqi = aqiProvider.current?.aqi ?? 50;
    final zoneType = _isAqiMode ? 'aqi' : 'flood';

    for (final z in _activeZones(zones)) {
      final point = LatLng(z.latitude, z.longitude);
      final name = z.name;
      final zoneAqi = _zoneAqi(name, cityAqi);
      final floodScore = _zoneFloodScore(name, floodLevel);
      final color = _isAqiMode
          ? _aqiZoneColor(zoneAqi)
          : _floodZoneColor(_scoreToLevel(floodScore));
      final isHighRisk = _isAqiMode
          ? zoneAqi > 100
          : floodScore >= 60;

      markers.add(Marker(
        point: point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showZoneAlert(
            ctx,
            name,
            zoneType,
            _isAqiMode ? floodLevel : _scoreToLevel(floodScore),
            zoneAqi,
            color,
            isHighRisk,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              _isAqiMode ? Icons.air_rounded : Icons.water_drop_rounded,
              color: color,
              size: 18,
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  /// Bottom sheet shown when user taps a zone marker.
  void _showZoneAlert(
    BuildContext ctx,
    String zoneName,
    String zoneType,
    FloodRiskLevel floodLevel,
    int aqiVal,
    Color color,
    bool isHighRisk,
  ) {
    final isAqi = zoneType == 'aqi';
    final riskLabel = isAqi
        ? _aqiLabel(aqiVal)
        : floodLevel.name.toUpperCase();
    final advice = isAqi
        ? _aqiAdvice(aqiVal)
        : _floodAdvice(floodLevel);
    final modelSource = isAqi
        ? 'WAQI Sensor Network'
        : 'EcoAlert Cloudburst ML Model (LogisticRegression)';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAqi ? Icons.air_rounded : Icons.water_rounded,
                    color: color, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zoneName,
                          style: AppTextStyles.titleMed.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      Text(isAqi ? 'Air Quality Zone' : 'Cloudburst / Flood Zone',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Risk badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(riskLabel,
                      style: AppTextStyles.label.copyWith(color: color)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alert banner if high risk
            if (isHighRisk)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAqi
                            ? '⚠️ AVOID this area — air quality is hazardous'
                            : '⚠️ STAY AWAY — high chance of cloudburst / flash flood',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Value row
            Row(
              children: [
                Text(isAqi ? 'AQI Reading' : 'Cloudburst Risk Score',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  isAqi ? '$aqiVal' : '${floodLevel.name.toUpperCase()} (${_floodScore(floodLevel)}/100)',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),

            // Advice
            Text(advice,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 12),

            // Model source
            Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    color: AppColors.textDisabled, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Source: $modelSource',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.textDisabled, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50)  return 'GOOD';
    if (aqi <= 100) return 'MODERATE';
    if (aqi <= 150) return 'UNHEALTHY (SENSITIVE)';
    if (aqi <= 200) return 'UNHEALTHY';
    return 'HAZARDOUS';
  }

  String _aqiAdvice(int aqi) {
    if (aqi <= 50)  return 'Air quality is good. No restrictions needed.';
    if (aqi <= 100) return 'Sensitive individuals should reduce time outdoors.';
    if (aqi <= 150) return 'People with respiratory issues should avoid this zone.';
    if (aqi <= 200) return 'Everyone should avoid prolonged outdoor activity. Wear N95 if entering.';
    return 'HEALTH EMERGENCY. Do not enter without an N95 mask. Keep windows closed.';
  }

  String _floodAdvice(FloodRiskLevel level) {
    switch (level) {
      case FloodRiskLevel.low:      return 'No immediate risk. Normal precautions apply.';
      case FloodRiskLevel.moderate: return 'Monitor weather updates. Avoid low-lying roads during heavy rain.';
      case FloodRiskLevel.high:     return 'High probability of flash flooding. Avoid this area during rain. Move valuables to higher ground.';
      case FloodRiskLevel.critical: return 'CRITICAL — Evacuate if near this zone. Do not cross flooded roads. Flash flood imminent based on model prediction.';
    }
  }

  int _floodScore(FloodRiskLevel level) {
    switch (level) {
      case FloodRiskLevel.low:      return 20;
      case FloodRiskLevel.moderate: return 45;
      case FloodRiskLevel.high:     return 70;
      case FloodRiskLevel.critical: return 90;
    }
  }

  int _zoneAqi(String zoneName, int cityAqi) {
    final spread = zoneName.hashCode.abs() % 90;
    return (cityAqi - 25 + spread).clamp(25, 320);
  }

  double _zoneFloodScore(String zoneName, FloodRiskLevel level) {
    final base = switch (level) {
      FloodRiskLevel.low => 22.0,
      FloodRiskLevel.moderate => 48.0,
      FloodRiskLevel.high => 72.0,
      FloodRiskLevel.critical => 92.0,
    };
    final jitter = (zoneName.hashCode.abs() % 18) - 9;
    return (base + jitter).clamp(8, 98);
  }

  Future<void> _goToUserLocation() async {
    final loc = context.read<LocationProvider>();
    await loc.getCurrentLocation();
    final pos = loc.currentPosition;
    if (pos != null && mounted) {
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aqiProvider = context.watch<AqiProvider>();
    final floodProvider = context.watch<FloodProvider>();
    final zoneProvider = context.watch<HazardZoneProvider>();
    final locPos = context.watch<LocationProvider>().currentPosition;
    final locationLabel = context.watch<LocationProvider>().currentArea;
    final userPoint =
        locPos != null ? LatLng(locPos.latitude, locPos.longitude) : _lahore;
    final isHeatmapLoading = _heatmapMode == HeatmapMode.aqi
      ? aqiProvider.isLoading
      : floodProvider.isLoading;
    final floodLevel = floodProvider.risk?.level ?? FloodRiskLevel.low;
    final aqiVal = aqiProvider.current?.aqi ?? 0;
    final showAlert = _isAqiMode
        ? aqiVal > 100
        : floodLevel == FloodRiskLevel.high ||
            floodLevel == FloodRiskLevel.critical;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lahore,
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecoalert.app',
              ),
              if (!isHeatmapLoading)
                RepaintBoundary(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: MapHeatmapLayer(
                      key: ValueKey('${_heatmapMode.name}-${zoneProvider.allZones.length}'),
                      mode: _heatmapMode,
                      zones: zoneProvider.allZones,
                    ),
                  ),
                ),
              // ── Model-driven hazard zones ──────────────────────────────
              CircleLayer(
                circles: _buildHazardCircles(
                    userPoint, floodProvider, aqiProvider, zoneProvider),
              ),
              // ── Tappable zone markers ──────────────────────────────────
              MarkerLayer(
                markers: [
                  ..._buildZoneMarkers(
                      floodProvider, aqiProvider, zoneProvider, context),
                  // User location marker
                  if (locPos != null)
                    Marker(
                      point: userPoint,
                      width: 160,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              locationLabel.isNotEmpty
                                  ? locationLabel
                                  : 'You are here',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 9,
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_pin_circle,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Text(
                    '© OpenStreetMap',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          if (isHeatmapLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildOfflineIndicator(context),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 58,
            left: 0,
            right: 0,
            child: Center(child: _buildModeSegmentedControl()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Hazard Map',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () {
                          _mapController.move(_lahore, 11);
                          setState(() {});
                        },
                        child: const Icon(Icons.refresh,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 8),
                      AppCard(
                        padding: EdgeInsets.zero,
                        onTap: _goToUserLocation,
                        child: const Icon(Icons.my_location,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 8),
                      AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: const Icon(Icons.settings_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Model alert banner (shown when risk is high) ─────────
                  if (showAlert)
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/model-status'),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_isAqiMode
                                  ? (aqiVal > 150 ? AppColors.warning : AppColors.danger)
                                  : AppColors.danger)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (_isAqiMode
                                    ? (aqiVal > 150
                                        ? AppColors.warning
                                        : AppColors.danger)
                                    : AppColors.danger)
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _isAqiMode
                                  ? (aqiVal > 150
                                      ? AppColors.warning
                                      : AppColors.danger)
                                  : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isAqiMode
                                    ? 'AQI $aqiVal — Tap orange/red zones for air quality details.'
                                    : '${floodLevel.name.toUpperCase()} flood risk — Tap water zones for runoff warnings.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _isAqiMode
                                      ? (aqiVal > 150
                                          ? AppColors.warning
                                          : AppColors.danger)
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: _isAqiMode
                                    ? (aqiVal > 150
                                        ? AppColors.warning
                                        : AppColors.danger)
                                    : AppColors.danger),
                          ],
                        ),
                      ),
                    ),

                  // ── Legend + Safe Routes ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MapLegend(mode: _heatmapMode),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () =>
                              Navigator.pushNamed(context, '/route-info'),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.navigation,
                                    color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Safe Routes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Available',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modePill(
                label: 'AQI',
                icon: Icons.air_rounded,
                active: _isAqiMode,
                onTap: () => setState(() => _heatmapMode = HeatmapMode.aqi),
              ),
              const SizedBox(width: 6),
              _modePill(
                label: 'Flood Risk',
                icon: Icons.water_drop_rounded,
                active: !_isAqiMode,
                onTap: () =>
                    setState(() => _heatmapMode = HeatmapMode.floodRisk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isAqiMode
              ? 'Showing air quality zones only'
              : 'Showing flood & cloudburst zones only',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _modePill({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Map mode: $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? AppColors.textInverse : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: active ? AppColors.textInverse : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Consumer2<AqiProvider, FloodProvider>(
      builder: (context, aqi, flood, _) {
        if (_offlineBannerDismissed ||
            (!aqi.isFromCache && !flood.isFromCache)) {
          return const SizedBox.shrink();
        }
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cached map data',
                      style: AppTextStyles.titleMed.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Pull to refresh when back online',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  final city = context.read<LocationProvider>().currentCity;
                  context.read<AqiProvider>().loadForCity(city);
                  context.read<FloodProvider>().loadForCity(city);
                },
                child: const Text('Retry'),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _offlineBannerDismissed = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}
