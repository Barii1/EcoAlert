import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/flood_model.dart';
import '../config/city_mappings.dart';
import 'demo_weather_source.dart'; // for WeatherDataSource abstract

/// Real weather data source using Open-Meteo API.
/// 100% FREE — no API key, no registration, no credit card.
/// Docs: https://open-meteo.com/en/docs
class OpenWeatherSource implements WeatherDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<RainfallData> fetchRainfall(String city) async {
    final coords = CityMappings.cityCoords[city];
    if (coords == null) {
      throw Exception('No coordinates for city: $city');
    }

    final lat = coords[0];
    final lon = coords[1];

    // Single API call gives us hourly precipitation for 2+ days.
    final response = await _dio.get(_baseUrl, queryParameters: {
      'latitude': lat,
      'longitude': lon,
      'hourly': 'precipitation',
      'current': 'precipitation',
      'forecast_days': 3,
      'timezone': 'auto',
    });

    final data = response.data;

    // Current precipitation rate (mm/hr).
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final mmPerHour = (current['precipitation'] as num?)?.toDouble() ?? 0;

    // Hourly precipitation array for 24h and 48h totals.
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
    final precipList = (hourly['precipitation'] as List<dynamic>?) ?? [];

    double mm24h = 0;
    double mm48h = 0;

    // Each entry is 1 hour of precipitation in mm.
    for (int i = 0; i < precipList.length && i < 72; i++) {
      final mm = (precipList[i] as num?)?.toDouble() ?? 0;
      if (i < 24) mm24h += mm;
      if (i < 48) mm48h += mm;
    }

    debugPrint('[Open-Meteo] $city: mmPerHour=$mmPerHour, mm24h=$mm24h, mm48h=$mm48h');

    return RainfallData(
      mm24h: mm24h,
      mmPerHour: mmPerHour,
      mm48h: mm48h,
      timestamp: DateTime.now(),
    );
  }
}
