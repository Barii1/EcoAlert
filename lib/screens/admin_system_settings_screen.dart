import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState
    extends State<AdminSystemSettingsScreen> {
  static const _keyAqiThreshold = 'admin_aqi_threshold';
  static const _keyFloodSensitivity = 'admin_flood_sensitivity';
  static const _keyAutoApprove = 'admin_auto_approve';
  static const _keyDebugLogging = 'admin_debug_logging';
  static const _keySyncInterval = 'admin_sync_interval';

  double _aqiThreshold = 150;
  String _floodSensitivity = 'Med';
  bool _autoApprove = false;
  bool _debugLogging = false;
  String _syncInterval = '30 mins';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _aqiThreshold =
          (prefs.getDouble(_keyAqiThreshold) ?? 150).clamp(0, 500).toDouble();
      _floodSensitivity = prefs.getString(_keyFloodSensitivity) ?? 'Med';
      _autoApprove = prefs.getBool(_keyAutoApprove) ?? false;
      _debugLogging = prefs.getBool(_keyDebugLogging) ?? false;
      _syncInterval = prefs.getString(_keySyncInterval) ?? '30 mins';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAqiThreshold, _aqiThreshold);
    await prefs.setString(_keyFloodSensitivity, _floodSensitivity);
    await prefs.setBool(_keyAutoApprove, _autoApprove);
    await prefs.setBool(_keyDebugLogging, _debugLogging);
    await prefs.setString(_keySyncInterval, _syncInterval);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgElevated,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Defaults',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Restore all system settings to their default values?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _aqiThreshold = 150;
      _floodSensitivity = 'Med';
      _autoApprove = false;
      _debugLogging = false;
      _syncInterval = '30 mins';
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'System Settings',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _resetDefaults,
            child: const Text('Reset',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ── Alert Thresholds ──────────────────────────────────────
                _SectionHeader(label: 'Alert Thresholds'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    // AQI slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Global AQI Trigger',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 14)),
                        _Badge(label: '${_aqiThreshold.toInt()}+'),
                      ],
                    ),
                    Slider(
                      value: _aqiThreshold,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.bgElevated,
                      onChanged: (v) => setState(() => _aqiThreshold = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0', style: _kHintStyle),
                        Text('250', style: _kHintStyle),
                        Text('500', style: _kHintStyle),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 16),
                    // Flood sensitivity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Flood Risk Sensitivity',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Model trigger variance',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                        _SegmentedControl(
                          options: const ['Low', 'Med', 'High'],
                          selected: _floodSensitivity,
                          onChanged: (v) =>
                              setState(() => _floodSensitivity = v),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Data Sources ─────────────────────────────────────────
                _SectionHeader(label: 'Data Sources'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _InfoTile(
                      icon: Icons.cloud_outlined,
                      iconColor: AppColors.info,
                      title: 'Open-Meteo API',
                      subtitle: 'Weather & Air Quality · Free tier',
                      trailing: _StatusDot(active: true),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _InfoTile(
                      icon: Icons.air,
                      iconColor: AppColors.warning,
                      title: 'WAQI API',
                      subtitle: 'Real-time AQI stations',
                      trailing: _StatusDot(active: true),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('Sync Interval',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14)),
                        ),
                        DropdownButton<String>(
                          value: _syncInterval,
                          dropdownColor: AppColors.bgCard,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          icon: const Icon(Icons.expand_more,
                              color: AppColors.textSecondary, size: 18),
                          items: ['15 mins', '30 mins', '1 hour', '6 hours']
                              .map((v) => DropdownMenuItem(
                                  value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _syncInterval = v);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── AI / Model Config ─────────────────────────────────────
                _SectionHeader(label: 'AI Configuration'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _ToggleRow(
                      title: 'Auto-Approve Low Risk',
                      subtitle: 'Skip manual review for reports < 20% risk',
                      value: _autoApprove,
                      onChanged: (v) => setState(() => _autoApprove = v),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _ToggleRow(
                      title: 'Debug Logging',
                      subtitle: 'Store raw inference data in prediction_logs',
                      value: _debugLogging,
                      onChanged: (v) => setState(() => _debugLogging = v),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Save button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bgPrimary),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── Shared styles ─────────────────────────────────────────────────────────────

const _kHintStyle = TextStyle(
    color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500);

// ── Small widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final isSelected = o == selected;
          return GestureDetector(
            onTap: () => onChanged(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary.withOpacity(0.15) : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.4))
                    : null,
              ),
              child: Text(
                o,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.success : AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          active ? 'Active' : 'Idle',
          style: TextStyle(
              color: active ? AppColors.success : AppColors.textSecondary,
              fontSize: 11),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.bgElevated,
          ),
        ],
      ),
    );
  }
}
