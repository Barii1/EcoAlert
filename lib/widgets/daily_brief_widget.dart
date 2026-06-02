import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/flood_provider.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../screens/daily_environment_screen.dart';
import '../services/daily_brief_service.dart';

class DailyBriefWidget extends StatefulWidget {
  const DailyBriefWidget({super.key});

  @override
  State<DailyBriefWidget> createState() => _DailyBriefWidgetState();
}

class _DailyBriefWidgetState extends State<DailyBriefWidget> {
  DailyBrief? _brief;
  bool   _loading = false;
  bool   _fetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), _fetch);
    });
  }

  Future<void> _fetch() async {
    if (_loading || !mounted) return;
    setState(() => _loading = true);
    try {
      final aqi   = context.read<AqiProvider>();
      final flood = context.read<FloodProvider>();
      final loc   = context.read<LocationProvider>();
      final wx    = context.read<WeatherProvider>();
      final auth  = context.read<AuthProvider>();
      final city  = loc.currentCity.isNotEmpty ? loc.currentCity : 'Lahore';

      final brief = await DailyBriefService.instance.fetchSummary(
        city:             city,
        aqi:              aqi.current?.aqi,
        aqiCategory:      aqi.current?.categoryLabel,
        floodRisk:        flood.risk?.levelLabel,
        floodProbability: flood.risk != null ? flood.risk!.riskScore / 100.0 : null,
        temperature:      wx.current?.temperature,
        humidity:         wx.current?.humidity.toDouble(),
        weatherDesc:      wx.current?.description,
        healthConditions: auth.currentUser?.healthConditions ?? [],
      );
      if (mounted) setState(() { _brief = brief; _loading = false; _fetched = true; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _fetched = true; });
    }
  }

  void _openFull() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DailyEnvironmentScreen(initialBrief: _brief),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFull,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.12), AppColors.bgCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's AI Brief",
                          style: AppTextStyles.titleMed.copyWith(
                              color: AppColors.textPrimary)),
                      Consumer<LocationProvider>(
                        builder: (_, loc, __) => Text(
                          loc.currentCity.isNotEmpty ? loc.currentCity : 'Your Location',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open', style: AppTextStyles.label.copyWith(
                          color: AppColors.primary, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary, size: 12),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live data chips — always visible, no waiting
            _buildLiveChips(),

            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),

            // AI brief content
            if (_loading)
              _shimmer()
            else if (_brief != null)
              _preview(_brief!.summary, _brief!.safetyTip)
            else if (_fetched)
              _fallback()
            else
              _shimmer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChips() {
    return Consumer3<AqiProvider, WeatherProvider, FloodProvider>(
      builder: (_, aqi, wx, flood, __) {
        final aqiReading = aqi.current;
        final weather    = wx.current;
        final risk       = flood.risk;

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (aqiReading != null)
              _chip(
                icon: Icons.air_rounded,
                color: aqiReading.color,
                label: 'AQI ${aqiReading.aqi}',
                sub: aqiReading.categoryLabel,
              ),
            if (weather != null) ...[
              _chip(
                icon: Icons.thermostat_rounded,
                color: const Color(0xFF42A5F5),
                label: '${weather.temperature.round()}°C',
                sub: weather.description,
              ),
              _chip(
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF80DEEA),
                label: '${weather.humidity}%',
                sub: 'Humidity',
              ),
              _chip(
                icon: Icons.air_outlined,
                color: AppColors.textSecondary,
                label: '${weather.windSpeed.round()} km/h',
                sub: weather.windDirectionLabel,
              ),
            ],
            if (risk != null)
              _chip(
                icon: Icons.water_rounded,
                color: risk.color,
                label: risk.levelLabel,
                sub: '${risk.riskScore}% risk',
              ),
          ],
        );
      },
    );
  }

  Widget _chip({
    required IconData icon,
    required Color color,
    required String label,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(sub,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preview(String summary, String tip) {
    final preview = summary.length > 120 ? '${summary.substring(0, 120)}…' : summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(preview,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (tip.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: AppColors.warning, size: 12),
              const SizedBox(width: 5),
              Expanded(
                child: Text(tip,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 12),
            const SizedBox(width: 5),
            Text('Ask the AI about today\'s conditions',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _shimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(0.9),
        const SizedBox(height: 6),
        _shimmerLine(0.7),
      ],
    );
  }

  Widget _shimmerLine(double widthFactor) {
    return LayoutBuilder(builder: (_, c) => Container(
      width: c.maxWidth * widthFactor,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.borderSubtle,
        borderRadius: BorderRadius.circular(5),
      ),
    ));
  }

  Widget _fallback() {
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline_rounded,
            color: AppColors.primary, size: 13),
        const SizedBox(width: 6),
        Text('Tap to open full report & AI chat',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
      ],
    );
  }
}
