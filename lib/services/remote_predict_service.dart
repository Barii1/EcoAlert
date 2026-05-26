import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/flood_model.dart';
import '../models/aqi_model.dart';

/// Calls the EcoAlert Flask cloudburst prediction API.
///
/// Endpoint: POST [AppConfig.uploadApiBaseUrl]/api/predict/cloudburst
///
/// The backend:
///   1. Receives latitude + longitude from Flutter
///   2. Calls Open-Meteo (free, no key) to get today's weather features
///   3. Runs the trained LogisticRegression cloudburst model
///   4. Returns risk_level, probability, and the weather features used
///
/// If the request fails (offline, server down, timeout) this throws so the
/// caller can fall back to the local rule-based FloodRiskCalculator.
class RemotePredictService {
  RemotePredictService._();
  static final RemotePredictService instance = RemotePredictService._();

  static const Duration _timeout = Duration(seconds: 15);

  String get _baseUrl => AppConfig.uploadApiBaseUrl;

  // ─────────────────────────────────────────────────────────────────────────
  // Cloudburst prediction — send lat/lon, backend handles the rest
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends user coordinates to Flask → backend fetches Open-Meteo weather
  /// and runs the trained cloudburst model → returns a [FloodRisk].
  ///
  /// [latitude] and [longitude] are the user's current GPS coordinates.
  /// [city] is optional display name.
  Future<FloodRisk> predictCloudburst({
    required double latitude,
    required double longitude,
    required String city,
    required RainfallData rainfall,   // still needed for FloodRisk model
  }) async {
    final body = jsonEncode({
      'latitude':  latitude,
      'longitude': longitude,
      'city':      city,
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/predict/cloudburst'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        '[RemotePredictService] cloudburst API returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _toFloodRisk(data, rainfall, city);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Alternative: send features directly (when you already have weather data)
  // ─────────────────────────────────────────────────────────────────────────

  Future<FloodRisk> predictCloudburstFromFeatures({
    required double temperature,
    required double humidity,
    required double pressure,
    required double cloudCover,
    required double windSpeed,
    required String city,
    required RainfallData rainfall,
  }) async {
    final body = jsonEncode({
      'temperature': temperature,
      'humidity':    humidity,
      'pressure':    pressure,
      'cloud_cover': cloudCover,
      'wind_speed':  windSpeed,
      'city':        city,
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/predict/cloudburst/features'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        '[RemotePredictService] features API returned ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _toFloodRisk(data, rainfall, city);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AQI — pass-through (no custom ML AQI model deployed yet)
  // AQI prediction now calls the Flask backend model endpoint.
  // ─────────────────────────────────────────────────────────────────────────

  Future<AqiReading> predictAqi({required AqiReading currentReading}) async {
    final body = jsonEncode({
      'pm25': currentReading.pm25,
      'pm10': currentReading.pm10,
      'no2': currentReading.no2,
      'o3': currentReading.o3,
      'co': currentReading.co,
      'city': currentReading.city,
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/predict/aqi'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        '[RemotePredictService] AQI API returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final predictedAqi = (data['predicted_aqi'] as num?)?.toInt() ?? currentReading.aqi;
    final category = AqiReading.categoryFromIndex(predictedAqi);

    debugPrint(
      '[RemotePredictService] AQI → $predictedAqi | model=${data['using_model'] == true} | city=${currentReading.city}',
    );

    return AqiReading(
      aqi: predictedAqi,
      category: category,
      pm25: currentReading.pm25,
      pm10: currentReading.pm10,
      o3: currentReading.o3,
      no2: currentReading.no2,
      co: currentReading.co,
      timestamp: DateTime.now(),
      city: currentReading.city,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model status (useful for admin/debug screen)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getModelStatus() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/predict/status'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('[RemotePredictService] status check failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Converter: API response → FloodRisk domain model
  // ─────────────────────────────────────────────────────────────────────────

  FloodRisk _toFloodRisk(
    Map<String, dynamic> data,
    RainfallData rainfall,
    String city,
  ) {
    final levelStr   = (data['risk_level'] as String? ?? 'Low').toLowerCase();
    final probability = (data['cloudburst_probability'] as num?)?.toDouble() ?? 0.0;
    final usingModel  = data['using_model'] as bool? ?? false;
    final features    = data['features_used'] as Map<String, dynamic>? ?? {};

    final FloodRiskLevel level = _parseLevel(levelStr);
    // Map 0-1 probability to 0-100 score for the existing FloodRisk model
    final int score = (probability * 100).round();

    final confidence = '${(probability * 100).toStringAsFixed(0)}%';
    final source     = usingModel ? 'AI model' : 'rule-based estimate';
    final explanation =
        'Cloudburst $source (probability: $confidence). '
        'Based on: temp ${features['temperature']?.toStringAsFixed(1) ?? '--'}°C, '
        'humidity ${features['humidity']?.toStringAsFixed(0) ?? '--'}%, '
        'cloud cover ${((features['cloud_cover'] ?? 0) / 8.0 * 100).toStringAsFixed(0)}%.';

    debugPrint(
      '[RemotePredictService] Cloudburst → $levelStr ($score) '
      '| prob=$probability | model=$usingModel | city=$city',
    );

    return FloodRisk(
      riskScore:     score,
      level:         level,
      rainfall:      rainfall,
      city:          city,
      affectedAreas: _affectedAreas(city, level),
      explanation:   explanation,
      calculatedAt:  DateTime.now(),
    );
  }

  FloodRiskLevel _parseLevel(String s) {
    switch (s) {
      case 'high':     return FloodRiskLevel.critical;
      case 'moderate': return FloodRiskLevel.high;
      default:         return FloodRiskLevel.low;
    }
  }

  List<String> _affectedAreas(String city, FloodRiskLevel level) {
    if (level == FloodRiskLevel.low) return [];
    const areas = {
      'Lahore':    ['Ravi River banks', 'Shahdara', 'Data Darbar area'],
      'Karachi':   ['Lyari River corridor', 'Orangi Town', 'Korangi'],
      'Peshawar':  ['Kabul River banks', 'Charsadda Road areas'],
      'Hyderabad': ['Indus River banks', 'Latifabad'],
      'Sukkur':    ['Indus floodplain', 'Rohri'],
      'Islamabad': ['Soan River areas', 'Margalla foothills'],
    };
    return areas[city] ?? ['Low-lying areas', 'River-adjacent zones'];
  }
}
