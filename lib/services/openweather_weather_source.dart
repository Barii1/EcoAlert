import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/city_mappings.dart';
import '../models/flood_model.dart';
import 'demo_weather_source.dart'; // for WeatherDataSource abstract

/// Real weather data source using OpenWeatherMap API.
class OpenWeatherSource implements WeatherDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  @override
  Future<RainfallData> fetchRainfall(String city) async {
    final mappedCity = CityMappings.getOwmCity(city);
    final response = await _dio.get(_baseUrl, queryParameters: {
      'q': mappedCity,
      'appid': AppConfig.openWeatherApiKey,
      'units': 'metric',
    });

    final data = response.data as Map<String, dynamic>? ?? {};
    final rain = data['rain'] as Map<String, dynamic>? ?? {};
    final mmPerHour = (rain['1h'] as num?)?.toDouble() ?? 0.0;

    // OpenWeather current endpoint doesn't include 24h/48h rain totals.
    // Use conservative estimates from current intensity so downstream logic
    // still receives complete RainfallData without changing model contracts.
    final mm24h = mmPerHour * 24;
    final mm48h = mmPerHour * 48;

    debugPrint(
      '[OpenWeather] $city: mmPerHour=$mmPerHour, mm24h=$mm24h, mm48h=$mm48h',
    );

    return RainfallData(
      mm24h: mm24h,
      mmPerHour: mmPerHour,
      mm48h: mm48h,
      timestamp: DateTime.now(),
    );
  }
}
