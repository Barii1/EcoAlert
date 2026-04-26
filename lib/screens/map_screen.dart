import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/aqi_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/map_heatmap_layer.dart';
import '../widgets/map_legend.dart';
import '../widgets/premium_ux.dart';

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

  List<CircleMarker> _buildHazardCircles(LatLng userPoint) {
    final circles = <CircleMarker>[];
    // Safe zone (500m) around user
    circles.add(
      CircleMarker(
        point: userPoint,
        radius: 500,
        useRadiusInMeter: true,
        color: AppColors.success.withOpacity(0.06),
        borderStrokeWidth: 2,
        borderColor: AppColors.success.withOpacity(0.4),
      ),
    );
    circles.add(CircleMarker(
      point: _lahore,
      radius: 800,
      useRadiusInMeter: true,
      color: AppColors.warning.withOpacity(0.25),
      borderStrokeWidth: 2,
      borderColor: AppColors.warning,
    ));
    circles.add(CircleMarker(
      point: const LatLng(31.5404, 74.3387),
      radius: 600,
      useRadiusInMeter: true,
      color: AppColors.danger.withOpacity(0.2),
      borderStrokeWidth: 2,
      borderColor: AppColors.danger,
    ));
    circles.add(CircleMarker(
      point: const LatLng(31.5050, 74.3700),
      radius: 500,
      useRadiusInMeter: true,
      color: AppColors.info.withOpacity(0.15),
      borderStrokeWidth: 2,
      borderColor: AppColors.info,
    ));
    return circles;
  }

  Future<void> _goToUserLocation() async {
    final role = context.read<AuthProvider>().currentRole;
    if (role == UserRole.general) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to enable location.'),
          ),
        );
      }
      return;
    }
    if (role != UserRole.premium) {
      if (mounted) {
        showPremiumFeatureDialog(
          context,
          featureName: 'Live GPS location & geo-based warnings',
        );
      }
      return;
    }
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
    final role = context.watch<AuthProvider>().currentRole;
    final aqiProvider = context.watch<AqiProvider>();
    final floodProvider = context.watch<FloodProvider>();
    final isGeneral = role == UserRole.general;
    final isPremium = role == UserRole.premium;
    final locPos = context.watch<LocationProvider>().currentPosition;
    final userPoint =
        locPos != null ? LatLng(locPos.latitude, locPos.longitude) : _lahore;
    final isHeatmapLoading = _heatmapMode == HeatmapMode.aqi
      ? aqiProvider.isLoading
      : floodProvider.isLoading;

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
                      key: ValueKey(_heatmapMode),
                      mode: _heatmapMode,
                    ),
                  ),
                ),
              CircleLayer(
                circles: _buildHazardCircles(userPoint),
              ),
              MarkerLayer(
                markers: [
                  if (isPremium && !isGeneral)
                    Marker(
                      point: userPoint,
                      width: 40,
                      height: 40,
                      child: Container(
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
                        child: const Icon(Icons.my_location,
                            color: Colors.white, size: 20),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MapLegend(mode: _heatmapMode),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.pushNamed(context, '/route-info'),
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
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Available',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textSecondary),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modePill(
            label: 'AQI',
            active: _heatmapMode == HeatmapMode.aqi,
            onTap: () => setState(() => _heatmapMode = HeatmapMode.aqi),
          ),
          const SizedBox(width: 6),
          _modePill(
            label: 'Flood Risk',
            active: _heatmapMode == HeatmapMode.floodRisk,
            onTap: () => setState(() => _heatmapMode = HeatmapMode.floodRisk),
          ),
        ],
      ),
    );
  }

  Widget _modePill({
    required String label,
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
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: active ? AppColors.textInverse : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline || _offlineBannerDismissed) {
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
                      'Offline Mode',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      'Last updated ${connectivity.lastUpdateLabel}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => connectivity.retryConnection(),
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
