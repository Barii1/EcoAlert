import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../models/aqi_model.dart';
import '../services/aqi_data_source.dart';
import '../services/cache_service.dart';
import '../services/open_meteo_aqi_source.dart';
import '../services/remote_predict_service.dart';

class AqiProvider extends ChangeNotifier {
  final AqiDataSource _source = OpenMeteoAqiSource();

  AqiReading? _current;
  List<HourlyAqiPoint> _hourly = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _city = 'Lahore';
  Position? _position;
  Timer? _refreshTimer;

  /// True when data came from cache (offline mode).
  bool _isFromCache = false;
  String? _cacheAge;

  AqiProvider() {
    _startRefreshTimer();
  }

  AqiReading? get current => _current;
  List<HourlyAqiPoint> get hourly => _hourly;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get city => _city;
  Position? get position => _position;
  bool get isFromCache => _isFromCache;
  String? get cacheAge => _cacheAge;

  Future<void> loadForCity(String city) async {
    _city = city;
    _position = null;
    return _load(city: city);
  }

  Future<void> loadForLocation(
    Position position, {
    String? cityLabel,
  }) async {
    _position = position;
    _city = cityLabel ?? _city;
    return _load(
      city: _city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _load({
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final sensorReading = await _source.fetchCurrent(
        city,
        latitude: latitude,
        longitude: longitude,
      );
      AqiReading finalReading;
      try {
        finalReading = await RemotePredictService.instance.predictAqi(
          currentReading: sensorReading,
        );
      } catch (modelError) {
        debugPrint(
            '[AqiProvider] AQI model failed, using Open-Meteo AQI: $modelError');
        finalReading = sensorReading;
      }

      _current = finalReading;
      _hourly = await _source.fetchHourly(
        city,
        latitude: latitude,
        longitude: longitude,
      );
      _isFromCache = false;
      _cacheAge = null;

      await CacheService.instance.saveAqi(city, _aqiToJson(finalReading));
    } catch (e) {
      debugPrint('[AqiProvider] Online fetch failed: $e - trying cache');
      final cached = await CacheService.instance.loadAqi(city);

      if (cached != null) {
        _current = _aqiFromJson(cached);
        _isFromCache = true;
        _cacheAge = await CacheService.instance.aqiCacheAge(city);
        _hasError = false;
        _errorMessage = null;
        debugPrint('[AqiProvider] Loaded from cache (age: $_cacheAge)');
      } else {
        _hasError = true;
        _errorMessage =
            'Could not load AQI data. Pull down to refresh or check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() {
    if (_position != null) {
      return loadForLocation(_position!, cityLabel: _city);
    }
    return loadForCity(_city);
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(minutes: AppConfig.refreshIntervalMinutes),
      (_) => retry(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _aqiToJson(AqiReading r) => {
        'aqi': r.aqi,
        'category': r.category.name,
        'pm25': r.pm25,
        'pm10': r.pm10,
        'o3': r.o3,
        'no2': r.no2,
        'so2': r.so2,
        'co': r.co,
        'city': r.city,
        'timestamp': r.timestamp.toIso8601String(),
      };

  AqiReading _aqiFromJson(Map<String, dynamic> j) {
    final aqiVal = (j['aqi'] as num?)?.toInt() ?? 0;
    final categoryStr = j['category'];
    AqiCategory category = AqiReading.categoryFromIndex(aqiVal);

    if (categoryStr is String) {
      for (final c in AqiCategory.values) {
        if (c.name == categoryStr) {
          category = c;
          break;
        }
      }
    }

    return AqiReading(
      aqi: aqiVal,
      category: category,
      pm25: (j['pm25'] as num?)?.toDouble() ?? 0,
      pm10: (j['pm10'] as num?)?.toDouble() ?? 0,
      o3: (j['o3'] as num?)?.toDouble() ?? 0,
      no2: (j['no2'] as num?)?.toDouble() ?? 0,
      so2: (j['so2'] as num?)?.toDouble() ?? 0,
      co: (j['co'] as num?)?.toDouble() ?? 0,
      city: j['city'] as String? ?? _city,
      timestamp:
          DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
