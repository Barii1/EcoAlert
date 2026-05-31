// Hassaan/Bilal: please ensure the alerts table exists in Supabase with at
// minimum these columns (the Flutter model reads both old and new names):
//   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
//   title text NOT NULL,
//   body text,           -- also read as 'description'
//   severity text,
//   city text,           -- also read as 'location'
//   type text,           -- 'flood' | 'air_quality' | 'cloudburst' | 'heatwave'
//   action_text text,
//   created_at timestamptz DEFAULT now(),
//   expires_at timestamptz  -- NULL means never expires
//
// Recommended RLS:
//   CREATE POLICY "read_all" ON alerts FOR SELECT USING (true);

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/supabase_tables.dart';
import '../models/alert_model.dart';
import '../services/supabase_service.dart';

class AlertProvider extends ChangeNotifier {
  // supabaseService is kept for backward API compatibility (used in addAlert);
  // all read/stream operations now go through Supabase.instance.client directly.
  AlertProvider({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService? _supabaseService;

  // ── State ──────────────────────────────────────────────────────────────────
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _dismissedIds = {};
  RealtimeChannel? _realtimeChannel;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  SupabaseClient get _db => Supabase.instance.client;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadDismissedIds();
    await fetchAlerts();
    _startRealtime();
  }

  Future<void> _loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('dismissed_alert_ids') ?? [];
    _dismissedIds = ids.toSet();
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _startRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _db
        .channel('public_alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseTables.alerts,
          callback: (_) => fetchAlerts(),
        )
        .subscribe();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchAlerts() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();

      // Fetch alerts that have not yet expired.
      // expires_at > now()  → active timed alert
      // expires_at IS NULL  → permanent alert (never expires)
      final data = await _db
          .from(SupabaseTables.alerts)
          .select()
          .or('expires_at.gt.$now,expires_at.is.null')
          .order('created_at', ascending: false)
          .limit(50);

      final all = (data as List)
          .map((r) => AlertModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();

      _alerts = _applyLocalFilters(all);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching alerts: $e';
      debugPrint('[AlertProvider] fetchAlerts error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Removes alerts the user dismissed and alerts older than [alertMaxAgeDays].
  List<AlertModel> _applyLocalFilters(List<AlertModel> raw) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: AppConfig.alertMaxAgeDays));
    return raw
        .where((a) => !_dismissedIds.contains(a.id))
        .where((a) => a.timestamp.isAfter(cutoff))
        .toList();
  }

  Future<void> retry() => fetchAlerts();

  // ── Dismiss ────────────────────────────────────────────────────────────────

  /// Removes the alert from the visible list and persists its ID to
  /// SharedPreferences so it stays dismissed across app restarts.
  /// Does NOT delete the row from Supabase.
  Future<void> dismissAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    _dismissedIds.add(id);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dismissed_alert_ids',
      _dismissedIds.toList(),
    );
  }

  // ── Write (admin) ──────────────────────────────────────────────────────────

  Future<void> addAlert(AlertModel alert) async {
    try {
      final data = alert.toJson()
        ..remove('id')
        ..['action_text'] = alert.actionText;
      data.remove('actionText');

      // Use SupabaseService if injected, otherwise fall back to direct client.
      if (_supabaseService != null) {
        await _supabaseService!.insertRow(SupabaseTables.alerts, data);
      } else {
        await _db.from(SupabaseTables.alerts).insert(data);
      }
    } catch (e) {
      _errorMessage = 'Failed to add alert: $e';
      notifyListeners();
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
