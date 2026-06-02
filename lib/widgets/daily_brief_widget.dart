import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
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
    // Delay slightly so providers have loaded their data first
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
            colors: [
              AppColors.primary.withOpacity(0.12),
              AppColors.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
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
                          loc.currentCity.isNotEmpty
                              ? loc.currentCity
                              : 'Your Location',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tap indicator
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

            // Content area
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

  Widget _preview(String summary, String tip) {
    // Show first 2 lines of summary only
    final preview = summary.length > 140 ? '${summary.substring(0, 140)}…' : summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(preview,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (tip.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: AppColors.warning, size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(tip,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 13),
            const SizedBox(width: 5),
            Text('Ask the AI about today\'s conditions',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontSize: 11)),
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
        const SizedBox(height: 6),
        _shimmerLine(0.5),
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
        const Icon(Icons.touch_app_outlined,
            color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text('Tap to open your daily environmental brief',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary)),
      ],
    );
  }
}
