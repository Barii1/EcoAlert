import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_ux.dart';

class AlertItem {
  const AlertItem({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.timeLabel,
    required this.severityLabel,
    required this.severityColor,
    required this.icon,
    required this.iconColor,
    required this.gradientColor,
    required this.category,
    required this.description,
    this.extraStat,
    this.aqiLabel,
  });

  final String title;
  final String subtitle;
  final String location;
  final String timeLabel;
  final String severityLabel;
  final Color severityColor;
  final IconData icon;
  final Color iconColor;
  final Color gradientColor;
  final String category;
  final String description;
  final String? extraStat;
  final String? aqiLabel;

  /// Create an AlertItem from AlertProvider's AlertModel for detail screen.
  static AlertItem fromAlertModel(AlertModel m) {
    Color severityColor;
    IconData icon;
    String category;
    if (m.type == 'flood') {
      severityColor = AppColors.danger;
      icon = Icons.warning;
      category = 'Flood';
    } else if (m.type == 'air_quality') {
      severityColor = AppColors.warning;
      icon = Icons.cloud;
      category = 'Smog/AQI';
    } else if (m.type == 'cloudburst') {
      severityColor = AppColors.warning;
      icon = Icons.water_drop;
      category = 'Cloudburst';
    } else if (m.type == 'heatwave') {
      severityColor = AppColors.success;
      icon = Icons.wb_sunny;
      category = 'Heatwave';
    } else {
      severityColor = AppColors.success;
      icon = Icons.info;
      category = 'Other';
    }
    return AlertItem(
      title: m.title,
      subtitle: m.description,
      location: m.location,
      timeLabel: m.getTimeAgo(),
      severityLabel: m.severity,
      severityColor: severityColor,
      icon: icon,
      iconColor: severityColor,
      gradientColor: severityColor,
      category: category,
      description: m.actionText,
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AlertsScreenBody();
  }
}

class _AlertsScreenBody extends StatefulWidget {
  const _AlertsScreenBody();

  @override
  State<_AlertsScreenBody> createState() => _AlertsScreenBodyState();
}

class _AlertsScreenBodyState extends State<_AlertsScreenBody> {
  String _selectedCategory = 'All';

  static const _filterChips = [
    'All',
    'Flood',
    'Smog/AQI',
    'Heatwave',
    'Cloudburst'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().fetchAlerts();
    });
  }

  List<AlertItem> _getFilteredAlerts(List<AlertModel> alerts) {
    final items = alerts.map(AlertItem.fromAlertModel).toList();
    if (_selectedCategory == 'All') return items;
    return items.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final isPremium = auth.isPremium;
    final filteredAlerts = _getFilteredAlerts(alertProvider.alerts);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onSettings: () {
                if (!isPremium) {
                  showPremiumFeatureDialog(
                    context,
                    featureName: 'Notification settings & geo alerts',
                  );
                  return;
                }
                Navigator.pushNamed(context, '/alert-settings');
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.p16, 0, AppSpacing.p16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPremium ? Icons.notifications_active : Icons.volume_off,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPremium
                            ? 'Priority notifications are active. You\'ll receive geo-based alerts for your area.'
                            : 'Upgrade to Premium for geo-based warnings and instant alerts.',
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!isPremium)
                      TextButton(
                        onPressed: () => showUpgradePromptDialog(context),
                        child: Text(
                          'Upgrade',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _FilterChips(
              selected: _selectedCategory,
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              chips: _filterChips,
            ),
            Expanded(
              child: alertProvider.isLoading && alertProvider.alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Loading alerts...',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    )
                  : filteredAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No alerts in this category',
                                style: AppTextStyles.titleMed
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You're all clear for now",
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filteredAlerts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final alert = filteredAlerts[index];
                            return _AlertCard(
                              alert: alert,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/alert-detail',
                                arguments: alert,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                ),
                child:
                    const Icon(Icons.eco, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Alerts',
                  style: AppTextStyles.displayMed
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
    required this.chips,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = chips[index];
          final active = label == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.titleMed.copyWith(
                    color:
                        active ? AppColors.textInverse : AppColors.textPrimary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});
  final AlertItem alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          border: Border(
            left: BorderSide(color: alert.severityColor, width: 4),
            top: BorderSide(color: AppColors.borderSubtle),
            right: BorderSide(color: AppColors.borderSubtle),
            bottom: BorderSide(color: AppColors.borderSubtle),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        alert.gradientColor.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(color: alert.iconColor, icon: alert.icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _SeverityPill(
                                label: alert.severityLabel,
                                color: alert.severityColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              alert.timeLabel,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                alert.location,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.subtitle,
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.45,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
