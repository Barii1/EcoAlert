// Hassaan/Bilal: run this SQL in the Supabase SQL Editor before using this screen:
//
// CREATE TABLE IF NOT EXISTS user_preferences (
//   user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
//   notif_aqi bool DEFAULT true,
//   notif_flood bool DEFAULT true,
//   notif_heatwave bool DEFAULT true,
//   notif_community bool DEFAULT true,
//   quiet_hours_start text DEFAULT '22:00',
//   quiet_hours_end text DEFAULT '07:00',
//   dark_mode bool DEFAULT false,
//   updated_at timestamptz DEFAULT now()
// );
// ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "own_row" ON user_preferences USING (auth.uid() = user_id);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  // ── UI state ───────────────────────────────────────────────────────────────
  bool _geoAlertsEnabled = true;
  bool _smogAqiAlerts = true;
  bool _floodAlerts = true;
  bool _heatAlerts = true;
  double _radiusKm = 5;
  bool _loaded = false;

  // ── SharedPreferences keys (local cache) ───────────────────────────────────
  static const _kGeo    = 'alert_geo_enabled';
  static const _kSmog   = 'alert_smog_enabled';
  static const _kFlood  = 'alert_flood_enabled';
  static const _kHeat   = 'alert_heat_enabled';
  static const _kRadius = 'alert_radius_km';

  // ── Supabase ───────────────────────────────────────────────────────────────
  static const _kTable = 'user_preferences';

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 1. Populate UI from SharedPreferences immediately (zero-latency first paint).
  /// 2. Then fetch from Supabase and reconcile — inserting a default row if
  ///    the user has never saved preferences before.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Step 1 — instant cache hit so the screen is usable right away.
    if (mounted) {
      setState(() {
        _geoAlertsEnabled = prefs.getBool(_kGeo)    ?? true;
        _smogAqiAlerts    = prefs.getBool(_kSmog)   ?? true;
        _floodAlerts      = prefs.getBool(_kFlood)  ?? true;
        _heatAlerts       = prefs.getBool(_kHeat)   ?? true;
        _radiusKm         = prefs.getDouble(_kRadius) ?? 5;
        _loaded           = true;
      });
    }

    // Step 2 — reconcile with Supabase in the background.
    await _fetchRemote(prefs);
  }

  Future<void> _fetchRemote(SharedPreferences prefs) async {
    final uid = _uid;
    if (uid == null) return; // not logged in — local prefs are the source of truth

    try {
      final row = await _db
          .from(_kTable)
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) {
        // First time — push current (default) values as the canonical row.
        await _insertDefaults(uid);
      } else {
        // Remote wins — update state and refresh cache.
        final aqi   = row['notif_aqi']   as bool? ?? true;
        final flood = row['notif_flood'] as bool? ?? true;
        final heat  = row['notif_heatwave'] as bool? ?? true;

        await Future.wait([
          prefs.setBool(_kSmog,  aqi),
          prefs.setBool(_kFlood, flood),
          prefs.setBool(_kHeat,  heat),
        ]);

        if (mounted) {
          setState(() {
            _smogAqiAlerts = aqi;
            _floodAlerts   = flood;
            _heatAlerts    = heat;
          });
        }
      }
    } catch (e) {
      debugPrint('[AlertSettings] Supabase fetch error: $e');
      // Screen already shows cached values — nothing more to do.
    }
  }

  Future<void> _insertDefaults(String uid) async {
    try {
      await _db.from(_kTable).insert({
        'user_id':            uid,
        'notif_aqi':          _smogAqiAlerts,
        'notif_flood':        _floodAlerts,
        'notif_heatwave':     _heatAlerts,
        'notif_community':    true,
        'quiet_hours_start':  '22:00',
        'quiet_hours_end':    '07:00',
        'dark_mode':          false,
      });
    } catch (e) {
      debugPrint('[AlertSettings] Supabase insert defaults error: $e');
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Updates SharedPreferences (immediate) then upserts to Supabase (async).
  /// _geoAlertsEnabled and _radiusKm are not in the schema so they stay
  /// SharedPreferences-only.
  Future<void> _save() async {
    // 1. Local cache — always succeeds and is instant.
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_kGeo,    _geoAlertsEnabled),
      prefs.setBool(_kSmog,   _smogAqiAlerts),
      prefs.setBool(_kFlood,  _floodAlerts),
      prefs.setBool(_kHeat,   _heatAlerts),
      prefs.setDouble(_kRadius, _radiusKm),
    ]);

    // 2. Remote — fire-and-forget; errors are non-fatal.
    _upsertRemote();
  }

  Future<void> _upsertRemote() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from(_kTable).upsert({
        'user_id':        uid,
        'notif_aqi':      _smogAqiAlerts,
        'notif_flood':    _floodAlerts,
        'notif_heatwave': _heatAlerts,
        'updated_at':     DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AlertSettings] Supabase upsert error: $e');
    }
  }

  /// Triggers haptic feedback, applies state mutation, then persists.
  void _set(VoidCallback fn) {
    HapticFeedback.lightImpact();
    setState(fn);
    _save(); // async, intentionally not awaited
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text('Alert Settings',
            style: AppTextStyles.titleLarge
                .copyWith(color: AppColors.textPrimary)),
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Section(
                  title: 'Geo Alerts',
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _geoAlertsEnabled,
                        onChanged: (v) => _set(() => _geoAlertsEnabled = v),
                        title: Text(
                          'Geo-based warnings',
                          style: AppTextStyles.titleMed.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Receive hazard alerts near your location.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
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
                                onChanged: (v) => _set(() => _radiusKm = v),
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
                        onChanged: (v) => _set(() => _floodAlerts = v),
                        title: Text('Flood',
                            style: AppTextStyles.titleMed.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ),
                      SwitchListTile(
                        value: _smogAqiAlerts,
                        onChanged: (v) => _set(() => _smogAqiAlerts = v),
                        title: Text('Smog / AQI',
                            style: AppTextStyles.titleMed.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ),
                      SwitchListTile(
                        value: _heatAlerts,
                        onChanged: (v) => _set(() => _heatAlerts = v),
                        title: Text('Heat',
                            style: AppTextStyles.titleMed.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Settings are saved automatically.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
    );
  }
}

// ── Section card (unchanged) ──────────────────────────────────────────────────

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
