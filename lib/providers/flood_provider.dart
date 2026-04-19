import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/flood_model.dart';
import '../services/demo_weather_source.dart';
import '../services/openweather_weather_source.dart';
import '../services/fallback_data_source.dart';
import '../services/flood_risk_calculator.dart';

class FloodProvider extends ChangeNotifier {
  // Uses real OpenWeatherMap API with automatic fallback to demo data on failure.
  final WeatherDataSource _weatherSource = FallbackWeatherSource(
    real: OpenWeatherSource(),
    fallback: DemoWeatherSource(),
  );
  final FloodRiskCalculator _calculator = FloodRiskCalculator();

  FloodRisk? _risk;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _city = 'Lahore';
  Timer? _refreshTimer;

  FloodProvider() {
    _startRefreshTimer();
  }

  FloodRisk? get risk => _risk;
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
      final rainfall = await _weatherSource.fetchRainfall(city);
      _risk = _calculator.calculate(rainfall, city);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not load flood risk data.';
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
