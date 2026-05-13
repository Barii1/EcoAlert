import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/aqi_model.dart';
import '../services/aqi_data_source.dart';
import '../services/demo_aqi_source.dart';
import '../services/waqi_aqi_source.dart';
import '../services/fallback_data_source.dart';
import '../services/remote_predict_service.dart';
import '../services/cache_service.dart';

class AqiProvider extends ChangeNotifier {
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
  bool get isFromCache => _isFromCache;
  String? get cacheAge => _cacheAge;

  // ─────────────────────────────────────────────────────────────────────────
  // Main load method
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadForCity(String city) async {
    _city = city;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    // ── Step 1: Try to fetch real sensor data ─────────────────────────────
    try {
      final sensorReading = await _source.fetchCurrent(city);

      // ── Step 2: Optionally enrich with ML model prediction ────────────
      AqiReading finalReading;
      try {
        finalReading = await RemotePredictService.instance.predictAqi(
          currentReading: sensorReading,
        );
      } catch (_) {
        // Model unavailable — use raw sensor data as-is
        finalReading = sensorReading;
      }

      _current = finalReading;
      _hourly = await _source.fetchHourly(city);
      _isFromCache = false;
      _cacheAge = null;

      // ── Step 3: Cache for offline use ─────────────────────────────────
      await CacheService.instance.saveAqi(city, _aqiToJson(finalReading));

    } catch (e) {
      // ── Step 4: Offline fallback ───────────────────────────────────────
      debugPrint('[AqiProvider] Online fetch failed: $e — trying cache');
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
        _errorMessage = 'No internet connection and no cached data available.';
      }
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

  // ─────────────────────────────────────────────────────────────────────────
  // JSON helpers (for cache storage)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _aqiToJson(AqiReading r) => {
        'aqi': r.aqi,
        'category': r.category,
        'pm25': r.pm25,
        'pm10': r.pm10,
        'o3': r.o3,
        'no2': r.no2,
        'co': r.co,
        'city': r.city,
        'timestamp': r.timestamp.toIso8601String(),
      };

  AqiReading _aqiFromJson(Map<String, dynamic> j) {
    final aqiVal = (j['aqi'] as num?)?.toInt() ?? 0;
    final categoryStr = j['category'];
    AqiCategory category = AqiReading.categoryFromIndex(aqiVal);
    
    // Try to parse category from string if available
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
      co: (j['co'] as num?)?.toDouble() ?? 0,
      city: j['city'] as String? ?? _city,
      timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
