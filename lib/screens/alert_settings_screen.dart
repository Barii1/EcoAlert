import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  bool _geoAlertsEnabled = true;
  bool _smogAqiAlerts = true;
  bool _floodAlerts = true;
  bool _heatAlerts = true;
  double _radiusKm = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text('Alert Settings', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Section(
            title: 'Geo Alerts',
            child: Column(
              children: [
                SwitchListTile(
                  value: _geoAlertsEnabled,
                  onChanged: (v) => setState(() => _geoAlertsEnabled = v),
                  title: Text(
                    'Geo-based warnings',
                    style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Receive hazard alerts near your location (demo).',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _geoAlertsEnabled ? 1 : 0.45,
                  child: IgnorePointer(
                    ignoring: !_geoAlertsEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert radius: ${_radiusKm.toStringAsFixed(0)} km',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          onChanged: (v) => setState(() => _radiusKm = v),
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.borderSubtle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Hazard Types',
            child: Column(
              children: [
                SwitchListTile(
                  value: _floodAlerts,
                  onChanged: (v) => setState(() => _floodAlerts = v),
                  title: Text('Flood', style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                ),
                SwitchListTile(
                  value: _smogAqiAlerts,
                  onChanged: (v) => setState(() => _smogAqiAlerts = v),
                  title: Text('Smog / AQI', style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                ),
                SwitchListTile(
                  value: _heatAlerts,
                  onChanged: (v) => setState(() => _heatAlerts = v),
                  title: Text('Heat', style: AppTextStyles.titleMed.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              'Demo note: settings are local-only and reset on app restart.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMed.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
