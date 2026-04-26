import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/aqi_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/danger_theme_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/aqi_card.dart';
import '../widgets/flood_risk_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/weather_forecast_widget.dart';
import '../widgets/offline_banner.dart';
import '../widgets/quick_tip_chip.dart';
import '../widgets/surface_card.dart';
import 'alerts_screen.dart';
import 'guide_detail_screen.dart';
import 'map_screen.dart';
import 'prep_checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _lastUpdatedTicker;
  late final PageController _environmentPageController;

  @override
  void initState() {
    super.initState();
    _environmentPageController = PageController(viewportFraction: 0.88);
    _lastUpdatedTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final city = auth.currentUser?.city ?? 'Lahore';
      Provider.of<AlertProvider>(context, listen: false).fetchAlerts();
      Provider.of<AqiProvider>(context, listen: false).loadForCity(city);
      Provider.of<FloodProvider>(context, listen: false).loadForCity(city);
      Provider.of<WeatherProvider>(context, listen: false).loadForCity(city);
    });
  }

  @override
  void dispose() {
    _lastUpdatedTicker?.cancel();
    _environmentPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dangerTheme = context.watch<DangerThemeProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final latestUpdated = _latestDataTimestamp(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              OfflineBanner(
                isOffline: !connectivity.isOnline,
                lastUpdated: latestUpdated,
              ),
              _buildHeader(context, authProvider, dangerTheme),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () async {
                    final auth =
                        Provider.of<AuthProvider>(context, listen: false);
                    final city = auth.currentUser?.city ?? 'Lahore';
                    await Future.wait([
                      Provider.of<AlertProvider>(context, listen: false)
                          .fetchAlerts(),
                      Provider.of<AqiProvider>(context, listen: false)
                          .loadForCity(city),
                      Provider.of<FloodProvider>(context, listen: false)
                          .loadForCity(city),
                      Provider.of<WeatherProvider>(context, listen: false)
                          .loadForCity(city),
                    ]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      const SizedBox(height: AppSpacing.p16),

                      // Weather Widget — the hero section
                      _buildWeatherSection(context),
                      const SizedBox(height: AppSpacing.p24),

                      // Environmental Conditions (AQI + Flood)
                      _buildEnvironmentSection(context),
                      const SizedBox(height: AppSpacing.p16),

                      // 3-day weather forecast
                      _buildForecastSection(context),
                      _buildLastUpdatedChip(latestUpdated),
                      const SizedBox(height: AppSpacing.p24),

                      // Active Alerts
                      _buildAlertsSection(context),
                      const SizedBox(height: AppSpacing.p24),

                      // Quick Actions Row
                      _buildQuickActions(context),
                      const SizedBox(height: AppSpacing.p24),

                      // Hazard Map Preview
                      Consumer<AqiProvider>(
                        builder: (context, aqi, _) {
                          return Consumer<FloodProvider>(
                            builder: (context, flood, _) {
                              return _buildMapPreviewCard(
                                context,
                                aqiValue: aqi.current?.aqi,
                                floodPercent: flood.risk?.riskScore,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.p24),

                      // Safety Tips
                      _buildQuickSafetyTips(context),
                      const SizedBox(height: AppSpacing.p16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── HEADER ───────────────────
  Widget _buildHeader(
      BuildContext context, AuthProvider authProvider, DangerThemeProvider dangerTheme) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p16,
        top: AppSpacing.p12,
        bottom: AppSpacing.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // App identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dangerTheme.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dangerTheme.glowColor,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EcoAlert',
                      style: AppTextStyles.headline.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        authProvider.currentUser?.city ?? 'Lahore',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dangerTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dangerTheme.accentColor.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dangerTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dangerTheme.statusText.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: dangerTheme.accentColor,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Notifications bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── WEATHER SECTION ───────────────────
  Widget _buildWeatherSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
      child: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          if (weatherProvider.isLoading && weatherProvider.current == null) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.radius20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (weatherProvider.current == null) {
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.radius20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        color: AppColors.textSecondary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Weather data unavailable',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: weatherProvider.retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return WeatherCard(weather: weatherProvider.current!);
        },
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
      child: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          final isOffline = !context.watch<ConnectivityProvider>().isOnline;
          return WeatherForecastWidget(
            isLoading: weatherProvider.isLoading,
            currentWeather: weatherProvider.current,
            showCachedBadge: isOffline && weatherProvider.current != null,
          );
        },
      ),
    );
  }

  // ─────────────────── ENVIRONMENT SECTION (AQI + FLOOD) ───────────────────
  Widget _buildEnvironmentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ENVIRONMENTAL CONDITIONS',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        SizedBox(
          height: 220,
          child: Consumer<AqiProvider>(
            builder: (context, aqi, _) {
              return Consumer<FloodProvider>(
                builder: (context, flood, _) {
                  final isOffline = !context.watch<ConnectivityProvider>().isOnline;
                  return PageView(
                    padEnds: false,
                    controller: _environmentPageController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: AppSpacing.p16, right: AppSpacing.p8),
                        child: aqi.isLoading && aqi.current == null
                            ? _buildLoadingCard()
                            : aqi.hasError && aqi.current == null
                                ? _buildErrorCard(
                                    aqi.errorMessage ?? 'Error', aqi.retry)
                                : aqi.current != null
                              ? _withCachedBadge(
                                showBadge: isOffline,
                                child: AqiCard(
                                  reading: aqi.current!,
                                  onTap: () => Navigator.pushNamed(
                                    context, '/aqi-detail',
                                    arguments: aqi.current),
                                ),
                                      )
                                    : const SizedBox.shrink(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: AppSpacing.p8, right: AppSpacing.p16),
                        child: flood.isLoading && flood.risk == null
                            ? _buildLoadingCard()
                            : flood.hasError && flood.risk == null
                                ? _buildErrorCard(
                                    flood.errorMessage ?? 'Error', flood.retry)
                                : flood.risk != null
                              ? _withCachedBadge(
                                showBadge: isOffline,
                                child: FloodRiskCard(
                                  risk: flood.risk!,
                                  onTap: () => Navigator.pushNamed(
                                    context, '/flood-detail',
                                    arguments: flood.risk),
                                ),
                                      )
                                    : _buildLoadingCard(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────── ALERTS SECTION ───────────────────
  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE ALERTS',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Consumer<AlertProvider>(
                builder: (context, alertProvider, _) {
                  if (alertProvider.alerts.isEmpty) return const SizedBox.shrink();
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'View all',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            if (alertProvider.isLoading && alertProvider.alerts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLoadingCard(height: 80),
              );
            }

            final alerts = alertProvider.alerts.take(3).toList();
            if (alerts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SurfaceCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'All clear',
                                style: AppTextStyles.titleMed.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No active hazard alerts right now.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AlertTile(
                    model: alert,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/alert-detail',
                      arguments: AlertItem.fromAlertModel(alert),
                    ),
                  ),
                )).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────── QUICK ACTIONS ───────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.camera_alt_rounded,
              label: 'Scan & Report',
              sublabel: 'Report a hazard',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/aqi-scan'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.map_rounded,
              label: 'Hazard Map',
              sublabel: 'View live map',
              color: AppColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── MAP PREVIEW ───────────────────
  Widget _buildMapPreviewCard(
    BuildContext context, {
    int? aqiValue,
    int? floodPercent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: 'Open live hazard map',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
          child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius20),
            border: Border.all(color: AppColors.borderSubtle),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgElevated,
                AppColors.primary.withOpacity(0.06),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle grid pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radius20),
                  child: CustomPaint(painter: _GridPatternPainter()),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radius20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Top-right badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom content
              Positioned(
                left: 16,
                bottom: 14,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hazard Map',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMapTag(aqiValue != null
                                ? 'AQI $aqiValue'
                                : 'AQI --'),
                            const SizedBox(width: 6),
                            _buildMapTag(floodPercent != null
                                ? 'Flood $floodPercent%'
                                : 'Flood --'),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textInverse, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── SAFETY TIPS ───────────────────
  Widget _buildQuickSafetyTips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SAFETY GUIDES',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            children: [
              QuickTipChip(
                icon: Icons.flood,
                label: 'Flood Safety',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuideDetailScreen(
                      title: 'Flood Safety',
                      category: 'Flood',
                      readTimeLabel: '8 min read',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              QuickTipChip(
                icon: Icons.air,
                label: 'Clean Air',
                color: AppColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuideDetailScreen(
                      title: 'Smog & Air Quality',
                      category: 'Smog',
                      readTimeLabel: '5 min read',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              QuickTipChip(
                icon: Icons.wb_sunny,
                label: 'Heatwave',
                color: AppColors.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuideDetailScreen(
                      title: 'Heatwave Preparedness',
                      category: 'Heatwave',
                      readTimeLabel: '6 min read',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              QuickTipChip(
                icon: Icons.emergency,
                label: 'Emergency',
                color: AppColors.danger,
                onTap: () => showPrepChecklist(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────── REUSABLE HELPERS ───────────────────

  Widget _buildLoadingCard({double height = 220}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildMapTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLastUpdatedChip(DateTime? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.p8,
        left: AppSpacing.p16,
        right: AppSpacing.p16,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withOpacity(0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatUpdatedAgo(timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withCachedBadge({required Widget child, required bool showBadge}) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.warning.withOpacity(0.35)),
            ),
            child: Text(
              'CACHED',
              style: AppTextStyles.label.copyWith(
                color: AppColors.warning,
                fontSize: 9,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _latestDataTimestamp(BuildContext context) {
    final aqiTimestamp = context.watch<AqiProvider>().current?.timestamp;
    final weatherTimestamp = context.watch<WeatherProvider>().current?.timestamp;

    if (aqiTimestamp == null) return weatherTimestamp;
    if (weatherTimestamp == null) return aqiTimestamp;
    return aqiTimestamp.isAfter(weatherTimestamp)
        ? aqiTimestamp
        : weatherTimestamp;
  }

  String _formatUpdatedAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes < 1 ? 1 : diff.inMinutes;
      return 'Updated $minutes minute${minutes == 1 ? '' : 's'} ago';
    }

    final hours = diff.inHours < 1 ? 1 : diff.inHours;
    return 'Updated $hours hour${hours == 1 ? '' : 's'} ago';
  }
}

// ─────────────────── ALERT TILE ───────────────────
class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.model, required this.onTap});

  final AlertModel model;
  final VoidCallback onTap;

  Color _colorForType(String type) {
    switch (type) {
      case 'flood':
        return AppColors.danger;
      case 'air_quality':
        return AppColors.warning;
      case 'cloudburst':
        return AppColors.info;
      case 'heatwave':
        return const Color(0xFFFF6D00);
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'flood':
        return Icons.water_rounded;
      case 'air_quality':
        return Icons.cloud_rounded;
      case 'cloudburst':
        return Icons.thunderstorm_rounded;
      case 'heatwave':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(model.type);
    final severity = model.severity.toUpperCase();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(model.type), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.title,
                      style: AppTextStyles.titleMed.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (severity == 'HIGH')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'HIGH',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.danger,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        Text(
                          model.getTimeAgo(),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        if (model.location.isNotEmpty) ...[
                          Text('  ·  ',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textDisabled)),
                          Flexible(
                            child: Text(
                              model.location,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── QUICK ACTION CARD ───────────────────
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $sublabel',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleMed.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─────────────────── GRID PATTERN PAINTER ───────────────────
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
