import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';

// ── Admin palette ─────────────────────────────────────────────────────────────
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kRed    = Color(0xFFEF4444);
const _kText   = Colors.white;
const _kSub    = Color(0xFF9CA3AF);
const _kDim    = Color(0xFF4B5563);

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key, required this.auth});
  final AuthProvider auth;

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  static const _keyPushNotifs   = 'admin_push_notifs';
  static const _keyRealtimeAlerts = 'admin_realtime_alerts';
  static const _keyAutoApproval = 'admin_auto_approve';
  static const _key2FA          = 'admin_2fa_enabled';
  static const _keySessionTimeout = 'admin_session_timeout';

  bool _pushNotifs    = true;
  bool _realtimeAlerts = true;
  bool _autoApproval  = false;
  bool _twoFA         = true;
  String _sessionTimeout = '15 mins';
  String _appVersion  = '—';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info  = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _pushNotifs      = prefs.getBool(_keyPushNotifs) ?? true;
      _realtimeAlerts  = prefs.getBool(_keyRealtimeAlerts) ?? true;
      _autoApproval    = prefs.getBool(_keyAutoApproval) ?? false;
      _twoFA           = prefs.getBool(_key2FA) ?? true;
      _sessionTimeout  = prefs.getString(_keySessionTimeout) ?? '15 mins';
      _appVersion      = '${info.version}+${info.buildNumber}';
      _loading         = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotifs, _pushNotifs);
    await prefs.setBool(_keyRealtimeAlerts, _realtimeAlerts);
    await prefs.setBool(_keyAutoApproval, _autoApproval);
    await prefs.setBool(_key2FA, _twoFA);
    await prefs.setString(_keySessionTimeout, _sessionTimeout);
  }

  void _toggle(void Function(bool) setter, bool val) {
    setState(() => setter(val));
    _save();
  }

  void _pickSessionTimeout() {
    const options = ['5 mins', '15 mins', '30 mins', '1 hour', 'Never'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Session Timeout',
                  style: TextStyle(
                      color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            ...options.map((o) => ListTile(
              title: Text(o, style: const TextStyle(color: _kText, fontSize: 14)),
              trailing: _sessionTimeout == o
                  ? const Icon(Icons.check_rounded, color: _kGreen, size: 18)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _sessionTimeout = o);
                _save();
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAuditLogs() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit log export coming soon'),
        backgroundColor: _kCard,
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        content: const Text('This will clear all locally cached data.',
            style: TextStyle(color: _kSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared'), backgroundColor: _kCard),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;
    final initial = user != null && user.username.isNotEmpty
        ? user.username.substring(0, user.username.length >= 2 ? 2 : 1).toUpperCase()
        : 'AA';

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                const Text('Settings',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // ── Account ────────────────────────────────────────────────
                _SectionLabel('Account'),
                const SizedBox(height: 10),
                _AccountCard(
                  initial: initial,
                  name: user?.username.isNotEmpty == true
                      ? user!.username
                      : 'Admin',
                  email: user?.email ?? 'admin@ecoalert.sys',
                  onEdit: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(height: 24),

                // ── System Configuration ───────────────────────────────────
                _SectionLabel('System Configuration'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _ToggleRow(
                    title: 'Push Notifications',
                    subtitle: 'Receive critical alerts on your device',
                    value: _pushNotifs,
                    onChanged: (v) => _toggle((x) => _pushNotifs = x, v),
                  ),
                  _Divider(),
                  _ToggleRow(
                    title: 'Real-time Alerts',
                    subtitle: 'Stream live telemetry data warnings',
                    value: _realtimeAlerts,
                    onChanged: (v) => _toggle((x) => _realtimeAlerts = x, v),
                  ),
                  _Divider(),
                  _ToggleRow(
                    title: 'Auto-Approval AI',
                    subtitle: 'Allow AI to triage low-level anomalies',
                    value: _autoApproval,
                    onChanged: (v) => _toggle((x) => _autoApproval = x, v),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Data Management ────────────────────────────────────────
                _SectionLabel('Data Management'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _ActionRow(
                    title: 'Export Audit Logs',
                    trailing: const Icon(
                        Icons.download_rounded, color: _kSub, size: 18),
                    onTap: _exportAuditLogs,
                  ),
                  _Divider(),
                  _ActionRow(
                    title: 'Clear Cache',
                    titleColor: _kRed,
                    trailing: const Icon(
                        Icons.delete_outline_rounded, color: _kRed, size: 18),
                    onTap: _clearCache,
                  ),
                  _Divider(),
                  _StorageRow(),
                ]),
                const SizedBox(height: 24),

                // ── Safety & Security ──────────────────────────────────────
                _SectionLabel('Safety & Security'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _InfoRow(
                    title: 'Two-Factor Authentication',
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: _kGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(_twoFA ? 'On' : 'Off',
                          style: TextStyle(
                              color: _twoFA ? _kGreen : _kSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  _Divider(),
                  _ActionRow(
                    title: 'Session Timeout',
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_sessionTimeout,
                          style: const TextStyle(color: _kSub, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: _kDim, size: 16),
                    ]),
                    onTap: _pickSessionTimeout,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── About ──────────────────────────────────────────────────
                _SectionLabel('About'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _InfoRow(
                    title: 'Version',
                    trailing: Text(_appVersion,
                        style: const TextStyle(color: _kSub, fontSize: 13)),
                  ),
                  _Divider(),
                  _ActionRow(
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.open_in_new_rounded,
                        color: _kDim, size: 16),
                    onTap: () => launchUrl(
                        Uri.parse('https://ecoalert.pk/privacy'),
                        mode: LaunchMode.externalApplication),
                  ),
                  _Divider(),
                  _ActionRow(
                    title: 'Terms of Service',
                    trailing: const Icon(Icons.open_in_new_rounded,
                        color: _kDim, size: 16),
                    onTap: () => launchUrl(
                        Uri.parse('https://ecoalert.pk/terms'),
                        mode: LaunchMode.externalApplication),
                  ),
                ]),
                const SizedBox(height: 32),

                // ── Sign out ───────────────────────────────────────────────
                _SignOutBtn(auth: widget.auth),
              ],
            ),
    );
  }
}

// ── Reusable building blocks ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: _kSub, fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.2),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: _kBorder, indent: 16, endIndent: 16);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: _kText, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: _kSub, fontSize: 12)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _kGreen,
            inactiveThumbColor: _kSub,
            inactiveTrackColor: _kBorder,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.trailing,
    required this.onTap,
    this.titleColor = _kText,
  });
  final String title;
  final Widget trailing;
  final VoidCallback onTap;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.trailing});
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: _kText, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const usage = 0.74;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Storage Usage',
                    style: TextStyle(
                        color: _kText, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Text('${(usage * 100).toInt()}%',
                  style: const TextStyle(color: _kSub, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: usage,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                  usage > 0.85 ? _kRed : Colors.white54),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.initial,
    required this.name,
    required this.email,
    required this.onEdit,
  });
  final String initial;
  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A), shape: BoxShape.circle),
            child: Center(
              child: Text(initial,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(email,
                  style: const TextStyle(color: _kSub, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Edit',
                  style: TextStyle(
                      color: _kSub, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutBtn extends StatelessWidget {
  const _SignOutBtn({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final nav = Navigator.of(context);
        await auth.logout();
        nav.pushNamedAndRemoveUntil('/login', (_) => false);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kRed.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text('Sign Out',
              style: TextStyle(
                  color: _kRed, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
