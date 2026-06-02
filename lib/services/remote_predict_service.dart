import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/aqi_model.dart';
import '../models/flood_model.dart';
import 'flood_risk_calculator.dart';

/// Calls the EcoAlert Flask prediction APIs.
///
/// Cloudburst predictions are shown separately from flood risk. Flood risk stays
/// based on rainfall/local conditions, while the backend model probability is
/// attached as cloudburst metadata for display.
class RemotePredictService {
  RemotePredictService._();
  static final RemotePredictService instance = RemotePredictService._();

  static const Duration _timeout = Duration(seconds: 15);

  String get _baseUrl => AppConfig.uploadApiBaseUrl;

  Future<FloodRisk> predictCloudburst({
    required double latitude,
    required double longitude,
    required String city,
    required RainfallData rainfall,
  }) async {
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
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
      'humidity': humidity,
      'pressure': pressure,
      'cloud_cover': cloudCover,
      'wind_speed': windSpeed,
      'city': city,
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

  Future<AqiReading> predictAqi({required AqiReading currentReading}) async {
    final body = jsonEncode({
      'pm25': currentReading.pm25,
      'pm10': currentReading.pm10,
      'no2': currentReading.no2,
      'so2': currentReading.so2,
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
    final predictedAqi =
        (data['predicted_aqi'] as num?)?.toInt() ?? currentReading.aqi;
    final predictedCategory = AqiReading.categoryFromIndex(predictedAqi);
    final confidence = (data['confidence'] as num?)?.toDouble();
    final usingModel = data['using_model'] == true;

    debugPrint(
      '[RemotePredictService] AQI model -> $predictedAqi | live=${currentReading.aqi} | model=$usingModel | city=${currentReading.city}',
    );

    return AqiReading(
      aqi: currentReading.aqi,
      category: currentReading.category,
      pm25: currentReading.pm25,
      pm10: currentReading.pm10,
      o3: currentReading.o3,
      no2: currentReading.no2,
      so2: currentReading.so2,
      co: currentReading.co,
      timestamp: DateTime.now(),
      city: currentReading.city,
      predictedAqi: predictedAqi,
      predictedCategory: predictedCategory,
      predictionConfidence: confidence,
      predictionUsingModel: usingModel,
    );
  }

  Future<Map<String, dynamic>> getModelStatus() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/predict/status'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('[RemotePredictService] status check failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  FloodRisk _toFloodRisk(
    Map<String, dynamic> data,
    RainfallData rainfall,
    String city,
  ) {
    final levelStr = (data['risk_level'] as String? ?? 'Low').toLowerCase();
    final probability =
        (data['cloudburst_probability'] as num?)?.toDouble() ?? 0.0;
    final usingModel = data['using_model'] as bool? ?? false;
    final features = data['features_used'] as Map<String, dynamic>? ?? {};
    final cloudburstLevel = _parseLevel(levelStr);
    final localFloodRisk = FloodRiskCalculator().calculate(rainfall, city);

    debugPrint(
      '[RemotePredictService] Cloudburst -> $levelStr (${(probability * 100).round()}%) '
      '| prob=$probability | model=$usingModel | city=$city',
    );

    return FloodRisk(
      riskScore: localFloodRisk.riskScore,
      level: localFloodRisk.level,
      rainfall: rainfall,
      city: city,
      affectedAreas: localFloodRisk.affectedAreas,
      explanation: localFloodRisk.explanation,
      calculatedAt: DateTime.now(),
      cloudburstProbability: probability,
      cloudburstLevel: cloudburstLevel,
      cloudburstUsingModel: usingModel,
      cloudburstFeatures: _numericFeatures(features),
    );
  }

  Map<String, double> _numericFeatures(Map<String, dynamic> features) {
    return features.map((key, value) {
      final number =
          value is num ? value.toDouble() : double.tryParse('$value');
      return MapEntry(key, number ?? 0.0);
    });
  }

  FloodRiskLevel _parseLevel(String s) {
    switch (s) {
      case 'high':
        return FloodRiskLevel.critical;
      case 'moderate':
        return FloodRiskLevel.high;
      default:
        return FloodRiskLevel.low;
    }
  }
}
