import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/city_mappings.dart';
import '../models/flood_model.dart';
import 'weather_data_source.dart';

/// Free rainfall estimates via Open-Meteo (no API key, works on web/CORS).
class OpenMeteoRainfallSource implements WeatherDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
  ));

  @override
  Future<RainfallData> fetchRainfall(String city) async {
    final coords = _coordsFor(city);
    if (coords == null) {
      throw Exception('No coordinates for $city');
    }

    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': coords[0],
        'longitude': coords[1],
        'hourly': 'precipitation',
        'past_hours': 48,
        'forecast_hours': 1,
        'timezone': 'auto',
      },
    );

    final hourly = response.data['hourly'] as Map<String, dynamic>? ?? {};
    final values =
        (hourly['precipitation'] as List<dynamic>?)?.cast<num>() ?? [];

    double sumLast(int hours) {
      if (values.isEmpty) return 0;
      final start = values.length > hours ? values.length - hours : 0;
      return values.sublist(start).fold<double>(0, (a, b) => a + b.toDouble());
    }

    final mm24h = sumLast(24);
    final mm48h = sumLast(48);
    final mmPerHour = values.isNotEmpty ? values.last.toDouble() : 0.0;

    debugPrint(
      '[OpenMeteoRain] $city: mm24h=$mm24h, mm48h=$mm48h, mm/h=$mmPerHour',
    );

    return RainfallData(
      mm24h: mm24h,
      mm48h: mm48h,
      mmPerHour: mmPerHour,
      timestamp: DateTime.now(),
    );
  }

  List<double>? _coordsFor(String city) {
    final normalized = city.trim();
    var coords = CityMappings.cityCoords[normalized];
    coords ??= CityMappings.cityCoords.entries
        .firstWhere(
          (e) => e.key.toLowerCase() == normalized.toLowerCase(),
          orElse: () => const MapEntry('', <double>[]),
        )
        .value;
    return coords.isEmpty ? null : coords;
  }
}
