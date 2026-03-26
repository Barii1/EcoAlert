import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';

class AlertProvider extends ChangeNotifier {
  AlertProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService? _firestoreService;
  StreamSubscription? _alertsSub;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Initialize: subscribe to Firestore real-time stream.
  Future<void> init() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    _alertsSub = _firestoreService!.alertsStream().listen(
      (alerts) {
        _alerts = alerts;
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

  /// One-time fetch (for pull-to-refresh).
  Future<void> fetchAlerts() async {
    if (_firestoreService == null || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await _firestoreService!.getAlerts();
    } catch (e) {
      _errorMessage = 'Error fetching alerts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => fetchAlerts();

  /// Add alert — writes to Firestore (stream auto-updates list).
  Future<void> addAlert(AlertModel alert) async {
    if (_firestoreService == null) return;
    try {
      await _firestoreService!.addAlert(alert);
    } catch (e) {
      _errorMessage = 'Failed to add alert: $e';
      notifyListeners();
    }
  }

  /// Remove alert — deletes from Firestore.
  Future<void> removeAlert(String id) async {
    if (_firestoreService == null) return;
    try {
      await _firestoreService!.deleteAlert(id);
    } catch (e) {
      _errorMessage = 'Failed to remove alert: $e';
      notifyListeners();
    }
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    super.dispose();
  }
}
