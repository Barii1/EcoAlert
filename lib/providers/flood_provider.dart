import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/flood_model.dart';
import '../services/notification_service.dart';
import '../services/open_meteo_rainfall_source.dart';
import '../services/flood_risk_calculator.dart';
import '../services/remote_predict_service.dart';
import '../services/cache_service.dart';

class FloodProvider extends ChangeNotifier {
  final OpenMeteoRainfallSource _openMeteoRain = OpenMeteoRainfallSource();
  final FloodRiskCalculator _localCalculator = FloodRiskCalculator();

  FloodRisk? _risk;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _city = 'Lahore';
  Timer? _refreshTimer;

  /// True when displayed data came from local cache (offline mode).
  bool _isFromCache = false;
  String? _cacheAge;

  // ── Debug: force high risk regardless of model output ────────────────────
  bool _debugForceHigh = false;
  bool get debugForceHigh => _debugForceHigh;

  void setDebugForceHigh(bool value) {
    _debugForceHigh = value;
    if (value && _risk != null) _applyForceHigh();
    notifyListeners();
  }

  void _applyForceHigh() {
    _risk = FloodRisk(
      riskScore: 95,
      level: FloodRiskLevel.critical,
      city: _risk!.city,
      explanation:
          '[DEBUG] Force-high mode active — simulating critical cloudburst risk.',
      affectedAreas: _risk!.affectedAreas.isNotEmpty
          ? _risk!.affectedAreas
          : ['All low-lying areas'],
      calculatedAt: DateTime.now(),
      rainfall: _risk!.rainfall,
    );
  }

  FloodProvider() {
    _startRefreshTimer();
  }

  FloodRisk? get risk => _risk;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get city => _city;
  bool get isFromCache => _isFromCache;
  String? get cacheAge => _cacheAge;

  // ─────────────────────────────────────────────────────────────────────────
  // Load by city name only (e.g. from home screen dropdown)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadForCity(String city) async {
    // Look up coordinates for the city — backend handles this too, but
    // providing them directly avoids the extra lookup on the server side.
    final coords = _cityCoords[city.toLowerCase().trim()];
    if (coords != null) {
      return _load(
        city: city,
        latitude: coords.$1,
        longitude: coords.$2,
      );
    }
    // City not in lookup — let the server resolve it
    return _load(city: city, latitude: null, longitude: null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load by GPS coordinates (called from LocationProvider)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadForLocation({
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    return _load(city: city, latitude: latitude, longitude: longitude);
  }

  Future<void> retry() => loadForCity(_city);

  // ─────────────────────────────────────────────────────────────────────────
  // Core load logic
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _load({
    required String city,
    required double? latitude,
    required double? longitude,
  }) async {
    _city = city;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    // ── Step 1: Fetch rainfall data from Open-Meteo ──────
    try {
      RainfallData rainfall;
      try {
        if (latitude != null && longitude != null) {
          rainfall = await _openMeteoRain.fetchRainfallAt(
            city: city,
            latitude: latitude,
            longitude: longitude,
          );
        } else {
          rainfall = await _openMeteoRain.fetchRainfall(city);
        }
      } catch (rainError) {
        debugPrint(
            '[FloodProvider] Open-Meteo rainfall failed, using zero-rain fallback: $rainError');
        rainfall = RainfallData(
          mm24h: 0,
          mm48h: 0,
          mmPerHour: 0,
          timestamp: DateTime.now(),
        );
      }

      // ── Step 2: Try the real ML model via Flask ───────────────────────
      rainfall = _preserveRecentRainfallIfRefreshDropsToZero(rainfall);

      FloodRisk result;
      try {
        if (latitude != null && longitude != null) {
          // Best path: send real GPS coords so backend fetches Open-Meteo
          result = await RemotePredictService.instance.predictCloudburst(
            latitude: latitude,
            longitude: longitude,
            city: city,
            rainfall: rainfall,
          );
        } else {
          // City-only fallback path
          result = await RemotePredictService.instance.predictCloudburst(
            latitude: _cityCoords[city.toLowerCase()]?.$1 ?? 31.5497,
            longitude: _cityCoords[city.toLowerCase()]?.$2 ?? 74.3436,
            city: city,
            rainfall: rainfall,
          );
        }
      } catch (modelError) {
        // Flask server unreachable → local rule-based calculator
        debugPrint(
            '[FloodProvider] Remote model failed, using local: $modelError');
        result = _localCalculator.calculate(rainfall, city);
      }

      // Apply debug force-high override before anything else reads the result
      if (_debugForceHigh) {
        _risk = result;
        _applyForceHigh();
      } else {
        _risk = result;
      }
      _isFromCache = false;
      _cacheAge = null;

      // Fire a local notification whenever risk is High or Critical
      final lvl = _risk!.level;
      if (lvl == FloodRiskLevel.high || lvl == FloodRiskLevel.critical) {
        NotificationService.instance
            .showCloudburstAlert(city, lvl.name)
            .catchError(
                (_) {}); // never crash the provider if notification fails
      }

      // ── Step 3: Save to cache for offline use ─────────────────────────
      await CacheService.instance.saveFlood(city, _floodRiskToJson(_risk!));
    } catch (e) {
      // ── Step 4: Everything online failed → serve cached data ─────────
      debugPrint('[FloodProvider] Online fetch failed: $e — trying cache');
      final cached = await CacheService.instance.loadFlood(city);

      if (cached != null) {
        _risk = _floodRiskFromJson(cached);
        _isFromCache = true;
        _cacheAge = await CacheService.instance.floodCacheAge(city);
        _hasError = false;
        _errorMessage = null;
      } else {
        _hasError = true;
        _errorMessage =
            'Could not load flood risk. Pull down to refresh or check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RainfallData _preserveRecentRainfallIfRefreshDropsToZero(
    RainfallData latest,
  ) {
    final previous = _risk?.rainfall;
    if (previous == null) return latest;

    final latestIsZero =
        latest.mm24h <= 0 && latest.mm48h <= 0 && latest.mmPerHour <= 0;
    final previousHasRain =
        previous.mm24h > 0 || previous.mm48h > 0 || previous.mmPerHour > 0;
    final previousIsRecent =
        DateTime.now().difference(previous.timestamp).inHours < 3;

    if (!latestIsZero || !previousHasRain || !previousIsRecent) {
      return latest;
    }

    debugPrint(
      '[FloodProvider] Preserving recent nonzero rainfall after zero refresh: '
      '24h=${previous.mm24h}, 48h=${previous.mm48h}, intensity=${previous.mmPerHour}',
    );

    return RainfallData(
      mm24h: previous.mm24h,
      mm48h: previous.mm48h,
      mmPerHour: previous.mmPerHour,
      temperature:
          latest.temperature != 0 ? latest.temperature : previous.temperature,
      humidity: latest.humidity != 0 ? latest.humidity : previous.humidity,
      timestamp: DateTime.now(),
    );
  }

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
  // City → coordinates (mirrors backend's CITY_COORDS)
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, (double, double)> _cityCoords = {
    'lahore': (31.5497, 74.3436),
    'karachi': (24.8607, 67.0011),
    'islamabad': (33.7294, 73.0931),
    'rawalpindi': (33.6007, 73.0679),
    'peshawar': (34.0151, 71.5249),
    'multan': (30.1978, 71.4711),
    'faisalabad': (31.4504, 73.1350),
    'quetta': (30.1798, 66.9750),
    'hyderabad': (25.3960, 68.3578),
    'sukkur': (27.7052, 68.8574),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // JSON serialization (for cache)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _floodRiskToJson(FloodRisk r) => {
        'riskScore': r.riskScore,
        'level': r.level.name,
        'city': r.city,
        'explanation': r.explanation,
        'affectedAreas': r.affectedAreas,
        'calculatedAt': r.calculatedAt.toIso8601String(),
        'cloudburstProbability': r.cloudburstProbability,
        'cloudburstLevel': r.cloudburstLevel?.name,
        'cloudburstUsingModel': r.cloudburstUsingModel,
        'cloudburstFeatures': r.cloudburstFeatures,
        'rainfall': {
          'mm24h': r.rainfall.mm24h,
          'mm48h': r.rainfall.mm48h,
          'mmPerHour': r.rainfall.mmPerHour,
          'temperature': r.rainfall.temperature,
          'humidity': r.rainfall.humidity,
        },
      };

  FloodRisk _floodRiskFromJson(Map<String, dynamic> j) {
    final levelStr = j['level'] as String? ?? 'low';
    final level = FloodRiskLevel.values.firstWhere(
      (e) => e.name == levelStr,
      orElse: () => FloodRiskLevel.low,
    );
    final cloudburstLevelStr = j['cloudburstLevel'] as String?;
    final cloudburstLevel = cloudburstLevelStr == null
        ? null
        : FloodRiskLevel.values.firstWhere(
            (e) => e.name == cloudburstLevelStr,
            orElse: () => FloodRiskLevel.low,
          );
    final r = j['rainfall'] as Map<String, dynamic>? ?? {};
    return FloodRisk(
      riskScore: (j['riskScore'] as num?)?.toInt() ?? 0,
      level: level,
      city: j['city'] as String? ?? _city,
      explanation: j['explanation'] as String? ?? '',
      affectedAreas: (j['affectedAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      calculatedAt: DateTime.tryParse(j['calculatedAt'] as String? ?? '') ??
          DateTime.now(),
      cloudburstProbability: (j['cloudburstProbability'] as num?)?.toDouble(),
      cloudburstLevel: cloudburstLevel,
      cloudburstUsingModel: j['cloudburstUsingModel'] as bool? ?? false,
      cloudburstFeatures:
          (j['cloudburstFeatures'] as Map<String, dynamic>? ?? {}).map(
        (key, value) {
          final number =
              value is num ? value.toDouble() : double.tryParse('$value');
          return MapEntry(key, number ?? 0.0);
        },
      ),
      rainfall: RainfallData(
        mm24h: (r['mm24h'] as num?)?.toDouble() ?? 0,
        mm48h: (r['mm48h'] as num?)?.toDouble() ?? 0,
        mmPerHour: (r['mmPerHour'] as num?)?.toDouble() ?? 0,
        temperature: (r['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (r['humidity'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.now(),
      ),
    );
  }
}
