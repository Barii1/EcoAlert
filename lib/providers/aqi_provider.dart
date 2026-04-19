import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/aqi_model.dart';
import '../services/aqi_data_source.dart';
import '../services/demo_aqi_source.dart';
import '../services/waqi_aqi_source.dart';
import '../services/fallback_data_source.dart';

class AqiProvider extends ChangeNotifier {
  // Uses real WAQI API with automatic fallback to demo data on failure.
  final AqiDataSource _source = FallbackAqiSource(
    real: WaqiAqiSource(),
    fallback: DemoAqiSource(),
  );

  AqiReading? _current;
  List<HourlyAqiPoint> _hourly = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _city = 'Lahore';
  Timer? _refreshTimer;

  AqiProvider() {
    _startRefreshTimer();
  }

  AqiReading? get current => _current;
  List<HourlyAqiPoint> get hourly => _hourly;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get city => _city;

  Future<void> loadForCity(String city) async {
    _city = city;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    try {
      _current = await _source.fetchCurrent(city);
      _hourly = await _source.fetchHourly(city);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not load AQI data. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => loadForCity(_city);

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(minutes: AppConfig.refreshIntervalMinutes),
      (_) => loadForCity(_city),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
