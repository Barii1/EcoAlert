import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/city_hazard_zones.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/flood_model.dart';
import '../models/hazard_zone_model.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/hazard_zone_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/surface_card.dart';

/// Optional navigation args for `/route-info`.
class RouteInfoArgs {
  const RouteInfoArgs({
    this.origin,
    this.destination,
  });

  final String? origin;
  final String? destination;
}

class RouteInfoScreen extends StatefulWidget {
  const RouteInfoScreen({super.key, this.args});

  final RouteInfoArgs? args;

  @override
  State<RouteInfoScreen> createState() => _RouteInfoScreenState();
}

class _RouteInfoScreenState extends State<RouteInfoScreen> {
  late String _origin;
  late String _destination;

  @override
  void initState() {
    super.initState();
    _origin = widget.args?.origin ?? '';
    _destination = widget.args?.destination ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_origin.isEmpty) {
      final loc = context.read<LocationProvider>();
      final area = loc.currentArea.trim();
      final city = loc.currentCity.trim();
      if (area.isNotEmpty) {
        _origin = 'Near $area';
      } else if (city.isNotEmpty) {
        _origin = 'Near $city';
      } else {
        _origin = 'Current location, ${AppConfig.defaultCity}';
      }
    }
    if (_destination.isEmpty) {
      final city = context.read<LocationProvider>().currentCity;
      final zones = context.read<HazardZoneProvider>().zonesForType('aqi');
      _destination = _defaultDestination(city, zones);
    }
  }

  String _defaultDestination(String city, List<HazardZoneModel> zones) {
    final loc = context.read<LocationProvider>();
    final pos = loc.currentPosition;
    if (pos != null) {
      return CityHazardZones.nearestSafeDestination(
          city, pos.latitude, pos.longitude);
    }
    // No GPS — pick safe point for city without coordinates
    return CityHazardZones.nearestSafeDestination(city, 0, 0);
  }

  List<_RouteOption> _buildRoutes(String city, FloodRiskLevel? floodLevel, int? aqi) {
    final floodZones = context.read<HazardZoneProvider>().zonesForType('flood');
    final avoidZone = floodZones.isNotEmpty ? floodZones.first.name : 'flood-prone areas';

    final highFlood = floodLevel == FloodRiskLevel.high ||
        floodLevel == FloodRiskLevel.critical;
    final poorAir = (aqi ?? 0) > 100;

    final benefits = <String>[
      'Avoids $avoidZone',
      if (highFlood) 'Skips active flood corridors',
      if (poorAir) 'Lower smog exposure where possible',
      'Based on live hazard map data',
    ];

    final caution = highFlood
        ? 'Passes near elevated flood risk — use caution'
        : 'Shorter route; may cross moderate-risk areas';

    return [
      _RouteOption(
        title: highFlood ? 'Safer detour route' : 'Recommended route',
        via: _recommendedVia(city),
        duration: highFlood ? '22 min' : '18 min',
        distance: highFlood ? '9.1 km' : '8.2 km',
        benefits: benefits,
        insight: highFlood
            ? 'EcoAlert detour: avoids highest-risk zones (+4 min vs shortest)'
            : 'EcoAlert route: balanced safety and travel time',
        recommended: true,
      ),
      _RouteOption(
        title: 'Alternative route',
        via: _alternativeVia(city),
        duration: '15 min',
        distance: '6.8 km',
        caution: caution,
        recommended: false,
      ),
    ];
  }

  String _recommendedVia(String city) {
    switch (city.toLowerCase()) {
      case 'karachi':
        return 'Via Shahrah-e-Faisal';
      case 'islamabad':
        return 'Via Kashmir Highway';
      case 'peshawar':
        return 'Via GT Road (east bypass)';
      default:
        return 'Via Jail Road';
    }
  }

  String _alternativeVia(String city) {
    switch (city.toLowerCase()) {
      case 'karachi':
        return 'Via MA Jinnah Road';
      case 'islamabad':
        return 'Via Murree Road';
      case 'peshawar':
        return 'Via Ring Road';
      default:
        return 'Via Ferozepur Road';
    }
  }

  Future<void> _openMaps(String origin, String destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareRoute(_RouteOption route) {
    Share.share(
      'EcoAlert safe route: ${route.via}\n'
      'From: $_origin\nTo: $_destination\n'
      '${route.duration} · ${route.distance}',
      subject: 'EcoAlert route suggestion',
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<LocationProvider>().currentCity;
    final flood = context.watch<FloodProvider>();
    final aqi = context.watch<AqiProvider>();
    final floodLevel = flood.risk?.level;
    final aqiValue = aqi.current?.aqi;
    final routes = _buildRoutes(city, floodLevel, aqiValue);
    final recommended = routes.first;
    final alternative = routes.length > 1 ? routes[1] : null;

    final liveReady = flood.risk != null || aqi.current != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, liveReady),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.p16,
                    AppSpacing.p8,
                    AppSpacing.p16,
                    AppSpacing.p24,
                  ),
                  children: [
                    _buildJourneyCard(),
                    const SizedBox(height: AppSpacing.p20),
                    _buildHazardContext(floodLevel, aqiValue),
                    const SizedBox(height: AppSpacing.p20),
                    _buildRouteCard(recommended, isPrimary: true),
                    if (alternative != null) ...[
                      const SizedBox(height: AppSpacing.p14),
                      _buildRouteCard(alternative, isPrimary: false),
                    ],
                    const SizedBox(height: AppSpacing.p16),
                    Text(
                      'Routes are suggestions based on hazard zones and live readings. '
                      'Always follow official advisories and road closures.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomBar(recommended),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool liveReady) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.p4,
        AppSpacing.p8,
        AppSpacing.p16,
        AppSpacing.p8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe Routes', style: AppTextStyles.headlinePrimary),
                Text(
                  'Hazard-aware navigation',
                  style: AppTextStyles.bodySmallSecondary,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p10,
              vertical: AppSpacing.p6,
            ),
            decoration: BoxDecoration(
              color: (liveReady ? AppColors.success : AppColors.warning)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radius20),
              border: Border.all(
                color: (liveReady ? AppColors.success : AppColors.warning)
                    .withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: liveReady ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.p6),
                Text(
                  liveReady ? 'LIVE DATA' : 'ESTIMATED',
                  style: AppTextStyles.label.copyWith(
                    color: liveReady ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard() {
    return SurfaceCard(
      child: Column(
        children: [
          _journeyRow(
            icon: Icons.trip_origin,
            iconColor: AppColors.success,
            label: 'From',
            value: _origin,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.p10),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 28,
                  color: AppColors.borderSubtle,
                ),
              ],
            ),
          ),
          _journeyRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.danger,
            label: 'To',
            value: _destination,
          ),
        ],
      ),
    );
  }

  Widget _journeyRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSecondary),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.titleLargePrimary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHazardContext(FloodRiskLevel? flood, int? aqi) {
    final floodLabel = flood?.name ?? 'unknown';
    final aqiLabel = aqi != null ? 'AQI $aqi' : 'AQI —';

    return Row(
      children: [
        Expanded(
          child: _contextChip(
            Icons.water_drop_outlined,
            'Flood: ${floodLabel.toUpperCase()}',
            _floodColor(flood),
          ),
        ),
        const SizedBox(width: AppSpacing.p8),
        Expanded(
          child: _contextChip(
            Icons.air_rounded,
            aqiLabel,
            aqi != null && aqi > 100 ? AppColors.warning : AppColors.success,
          ),
        ),
      ],
    );
  }

  Color _floodColor(FloodRiskLevel? level) {
    switch (level) {
      case FloodRiskLevel.critical:
      case FloodRiskLevel.high:
        return AppColors.danger;
      case FloodRiskLevel.moderate:
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _contextChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p10,
        vertical: AppSpacing.p8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radius12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.p6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.label.copyWith(color: color, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(_RouteOption route, {required bool isPrimary}) {
    final accent = isPrimary ? AppColors.success : AppColors.warning;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              border: isPrimary
                  ? Border.all(color: AppColors.success.withOpacity(0.35), width: 1)
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.radius16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.p8,
                        vertical: AppSpacing.p4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radius8),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: Text(
                        isPrimary ? 'RECOMMENDED' : 'CAUTION',
                        style: AppTextStyles.label.copyWith(
                          color: accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isPrimary ? Icons.shield_outlined : Icons.warning_amber_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p12),
                Text(route.title, style: AppTextStyles.titleLargePrimary),
                const SizedBox(height: 4),
                Text(route.via, style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSpacing.p14),
                Row(
                  children: [
                    _statChip(Icons.schedule_rounded, route.duration, 'Duration'),
                    const SizedBox(width: AppSpacing.p8),
                    _statChip(Icons.route_rounded, route.distance, 'Distance'),
                  ],
                ),
                if (route.benefits != null) ...[
                  const SizedBox(height: AppSpacing.p14),
                  ...route.benefits!.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.p6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: AppSpacing.p8),
                          Expanded(
                            child: Text(b, style: AppTextStyles.bodySecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (route.caution != null) ...[
                  const SizedBox(height: AppSpacing.p10),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.p10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radius8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.p8),
                        Expanded(
                          child: Text(
                            route.caution!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (route.insight != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.p12),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radius16),
                  bottomRight: Radius.circular(AppSpacing.radius16),
                ),
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.p8),
                  Expanded(
                    child: Text(
                      route.insight!,
                      style: AppTextStyles.bodySmallSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p12,
          vertical: AppSpacing.p8,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radius8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.p8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.titleMedPrimary),
                Text(label, style: AppTextStyles.labelSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(_RouteOption recommended) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p12,
        AppSpacing.p16,
        AppSpacing.p20,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareRoute(recommended),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.p14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(_origin, _destination),
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.p14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteOption {
  const _RouteOption({
    required this.title,
    required this.via,
    required this.duration,
    required this.distance,
    this.benefits,
    this.caution,
    this.insight,
    required this.recommended,
  });

  final String title;
  final String via;
  final String duration;
  final String distance;
  final List<String>? benefits;
  final String? caution;
  final String? insight;
  final bool recommended;
}
