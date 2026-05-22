import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/supabase_tables.dart';
import '../models/alert_model.dart';
import '../services/supabase_service.dart';

class AlertProvider extends ChangeNotifier {
  AlertProvider({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService? _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _alertsSubscription;
  bool _isStreaming = false;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> init() async {
    if (_supabaseService == null) {
      _alerts = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    await fetchAlerts();
    _startStream();
  }

  void _startStream() {
    if (_supabaseService == null || _isStreaming) return;
    _isStreaming = true;
    _alertsSubscription = _supabaseService!
        .streamTable(
          SupabaseTables.alerts,
          primaryKeys: ['id'],
          orderBy: 'timestamp',
          descending: true,
          limit: 50,
        )
        .listen(
          (rows) {
            _alerts = _filterRecent(rows.map(AlertModel.fromJson).toList());
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Error streaming alerts: $e';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> fetchAlerts() async {
    if (_isLoading) return;
    if (_supabaseService == null) {
      _alerts = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _supabaseService!.getTable(
        SupabaseTables.alerts,
        orderBy: 'timestamp',
        descending: true,
        limit: 50,
      );
      _alerts = _filterRecent(rows.map(AlertModel.fromJson).toList());
    } catch (e) {
      _errorMessage = 'Error fetching alerts: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => fetchAlerts();

  Future<void> addAlert(AlertModel alert) async {
    if (_supabaseService == null) return;
    try {
      final data = alert.toJson()
        ..remove('id')
        ..['action_text'] = alert.actionText;
      data.remove('actionText');
      await _supabaseService!.insertRow(SupabaseTables.alerts, data);
    } catch (e) {
      _errorMessage = 'Failed to add alert: $e';
      notifyListeners();
    }
  }

  List<AlertModel> _filterRecent(List<AlertModel> alerts) {
    final cutoff = DateTime.now().subtract(
      Duration(days: AppConfig.alertMaxAgeDays),
    );
    return alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
