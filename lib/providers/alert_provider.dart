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

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// No Firebase — empty alerts until user signs in.
  Future<void> init() async {
    if (_isUsingFirebase) return;
    _alerts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

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

  void disposeFirestore() {
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
    _isUsingFirebase = false;
    _alerts = [];
    _isLoading = false;
    notifyListeners();
  }

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

    _alerts = [];
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
    }
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
