import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/premium_ux.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _offlineBannerDismissed = false;
  bool _showFlood = true;
  bool _showAqi = true;
  bool _showReports = true;

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
    if (_showFlood) {
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
    }
    if (_showAqi) {
      circles.add(CircleMarker(
        point: const LatLng(31.5050, 74.3700),
        radius: 500,
        useRadiusInMeter: true,
        color: AppColors.info.withOpacity(0.15),
        borderStrokeWidth: 2,
        borderColor: AppColors.info,
      ));
    }
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

  void _showRiskZoneDetail() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning,
                      color: AppColors.danger, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('High Risk Zone',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppColors.textPrimary)),
                      Text('Flood zone — Ravi River banks',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('View on Map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/route-info');
                    },
                    child: const Text('Get Safe Route'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentRole;
    final isGeneral = role == UserRole.general;
    final isPremium = role == UserRole.premium;
    final locPos = context.watch<LocationProvider>().currentPosition;
    final userPoint =
        locPos != null ? LatLng(locPos.latitude, locPos.longitude) : _lahore;

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
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildOfflineIndicator(context),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hazard Zones',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            _legendRow(AppColors.success, 'Safe Zone (500m)'),
                            const SizedBox(height: 4),
                            _legendRow(AppColors.danger, 'High Risk'),
                            const SizedBox(height: 4),
                            _legendRow(AppColors.warning, 'Medium Risk'),
                            const SizedBox(height: 4),
                            _legendRow(AppColors.info, 'Safe Route'),
                          ],
                        ),
                      ),
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
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _layerToggle('Flood', _showFlood,
                            (v) => setState(() => _showFlood = v)),
                        const SizedBox(width: 12),
                        _layerToggle('AQI', _showAqi,
                            (v) => setState(() => _showAqi = v)),
                        const SizedBox(width: 12),
                        _layerToggle('Reports', _showReports,
                            (v) => setState(() => _showReports = v)),
                      ],
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

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _layerToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (_) => onChanged(!value),
                activeColor: AppColors.primary,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected))
                    return AppColors.primary;
                  return AppColors.borderSubtle;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
