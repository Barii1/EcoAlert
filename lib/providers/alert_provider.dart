import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/firestore_paths.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';

class AlertProvider extends ChangeNotifier {
  AlertProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService? _firestoreService;
  StreamSubscription<List<Map<String, dynamic>>>? _alertsSubscription;
  bool _isUsingFirebase = false;
  bool _seeded = false;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Canonical demo alerts (local + Firestore seed source).
  static final List<AlertModel> _demoAlerts = [
    AlertModel(
      id: 'demo-1',
      title: 'River level rising — Ravi corridor',
      description:
          'Sustained rainfall may cause localized bank overflow in low-lying wards.',
      severity: 'High',
      location: 'Lahore, Punjab',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: 'flood',
      actionText:
          'Avoid flood-prone underpasses; move vehicles to higher ground.',
    ),
    AlertModel(
      id: 'demo-2',
      title: 'AQI elevated — sensitive groups',
      description: 'Particulate levels are trending upward across the metro.',
      severity: 'Moderate',
      location: 'Lahore, Punjab',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      type: 'air_quality',
      actionText: 'Limit prolonged outdoor exertion; wear a mask outdoors.',
    ),
    AlertModel(
      id: 'demo-3',
      title: 'Heat stress advisory',
      description: 'Heat index is peaking mid-afternoon with dry winds.',
      severity: 'Moderate',
      location: 'Karachi, Sindh',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      type: 'heatwave',
      actionText: 'Stay hydrated; avoid direct sun during peak hours.',
    ),
    AlertModel(
      id: 'demo-4',
      title: 'Cloudburst risk — hill runoff',
      description: 'Short-duration intense rainfall possible on eastern ridges.',
      severity: 'High',
      location: 'Murree, Punjab',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: 'cloudburst',
      actionText: 'Postpone travel on mountain roads; watch for flash floods.',
    ),
  ];

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Local demo baseline (no Firestore subscription).
  Future<void> init() async {
    if (_isUsingFirebase) return;
    _alerts = List<AlertModel>.from(_demoAlerts);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Call after Firebase login to switch from demo to real data.
  void initFirestore() {
    if (_firestoreService == null) return;

    _isUsingFirebase = true;
    _alertsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _alertsSubscription = _firestoreService!
        .streamCollection(
          FirestorePaths.alerts,
          orderBy: 'timestamp',
          descending: true,
          limit: 50,
        )
        .listen(
          (data) {
            if (!_seeded && data.isEmpty) {
              _seeded = true;
              unawaited(_seedFirestoreIfNeeded());
            }
            _alerts = data.map(AlertModel.fromJson).toList();
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

  Future<void> _seedFirestoreIfNeeded() async {
    final fs = _firestoreService;
    if (fs == null) return;
    try {
      for (final alert in _demoAlerts) {
        final payload = Map<String, dynamic>.from(alert.toJson())..remove('id');
        await fs.addDoc(FirestorePaths.alerts, payload);
      }
    } catch (e) {
      _errorMessage = 'Failed to seed alerts: $e';
      notifyListeners();
    }
  }

  /// Call on demo logout to stop listening and revert to demo data.
  void disposeFirestore() {
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
    _isUsingFirebase = false;
    _seeded = false;
    _alerts = List<AlertModel>.from(_demoAlerts);
    _isLoading = false;
    notifyListeners();
  }

  /// One-time fetch (pull-to-refresh) or initial load helper.
  Future<void> fetchAlerts() async {
    if (_isLoading) return;

    if (_isUsingFirebase && _firestoreService != null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        final rows = await _firestoreService!.getCollection(
          FirestorePaths.alerts,
          orderBy: 'timestamp',
          descending: true,
          limit: 50,
        );
        _alerts = rows.map(AlertModel.fromJson).toList();
      } catch (e) {
        _errorMessage = 'Error fetching alerts: $e';
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    _alerts = List<AlertModel>.from(_demoAlerts);
    notifyListeners();
  }

  Future<void> retry() => fetchAlerts();

  Future<void> addAlert(AlertModel alert) async {
    if (_isUsingFirebase) {
      if (_firestoreService == null) return;
      try {
        final data = Map<String, dynamic>.from(alert.toJson())..remove('id');
        data['timestamp'] = FieldValue.serverTimestamp();
        await _firestoreService!.addDoc(FirestorePaths.alerts, data);
      } catch (e) {
        _errorMessage = 'Failed to add alert: $e';
        notifyListeners();
      }
      return;
    }

    _alerts = [alert, ..._alerts];
    notifyListeners();
  }

  Future<void> removeAlert(String id) async {
    if (_isUsingFirebase) {
      if (_firestoreService == null) return;
      try {
        await _firestoreService!.deleteDoc(FirestorePaths.alertDoc(id));
      } catch (e) {
        _errorMessage = 'Failed to remove alert: $e';
        notifyListeners();
      }
      return;
    }

    _alerts = _alerts.where((a) => a.id != id).toList();
    notifyListeners();
  }

  void clearAlerts() {
    if (_isUsingFirebase) return;
    _alerts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
