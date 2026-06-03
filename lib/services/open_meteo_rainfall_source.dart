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

    return fetchRainfallAt(
      city: city,
      latitude: coords[0],
      longitude: coords[1],
    );
  }

  Future<RainfallData> fetchRainfallAt({
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'hourly': [
          'precipitation',
          'rain',
          'temperature_2m',
          'relative_humidity_2m',
        ].join(','),
        'past_days': 2,
        'forecast_days': 1,
        'timezone': 'auto',
      },
    );

    final hourly = response.data['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List<dynamic>?)
            ?.map((value) => DateTime.tryParse(value.toString()))
            .toList() ??
        <DateTime?>[];
    final rainValues = (hourly['rain'] as List<dynamic>?)?.cast<num>() ?? [];
    final precipitationValues =
        (hourly['precipitation'] as List<dynamic>?)?.cast<num>() ?? [];
    final valueCount = [
      times.length,
      rainValues.length,
      precipitationValues.length,
    ].reduce((a, b) => a > b ? a : b);
    final values = List<double>.generate(valueCount, (index) {
      final rain =
          index < rainValues.length ? rainValues[index].toDouble() : 0.0;
      final precipitation = index < precipitationValues.length
          ? precipitationValues[index].toDouble()
          : 0.0;
      return rain > precipitation ? rain : precipitation;
    });
    final temperatures =
        (hourly['temperature_2m'] as List<dynamic>?)?.cast<num>() ?? <num>[];
    final humidities =
        (hourly['relative_humidity_2m'] as List<dynamic>?)?.cast<num>() ??
            <num>[];
    final now = DateTime.now();

    double sumWindow(Duration duration) {
      var total = 0.0;
      for (var i = 0; i < values.length && i < times.length; i++) {
        final t = times[i];
        if (t == null) continue;
        if (t.isAfter(now)) continue;
        if (!t.isBefore(now.subtract(duration))) {
          total += values[i].toDouble();
        }
      }
      return total;
    }

    int latestPastIndex() {
      for (var i = times.length - 1; i >= 0; i--) {
        final t = times[i];
        if (t != null && !t.isAfter(now)) return i;
      }
      return values.isEmpty ? -1 : values.length - 1;
    }

    final latestIndex = latestPastIndex();
    final mm24h = sumWindow(const Duration(hours: 24));
    final mm48h = sumWindow(const Duration(hours: 48));
    final mmPerHour = latestIndex >= 0 && latestIndex < values.length
        ? values[latestIndex].toDouble()
        : 0.0;
    final temperature = latestIndex >= 0 && latestIndex < temperatures.length
        ? temperatures[latestIndex].toDouble()
        : 0.0;
    final humidity = latestIndex >= 0 && latestIndex < humidities.length
        ? humidities[latestIndex].toDouble()
        : 0.0;

    debugPrint(
      '[OpenMeteoRain] $city: mm24h=$mm24h, mm48h=$mm48h, mm/h=$mmPerHour, temp=$temperature, humidity=$humidity',
    );

    return RainfallData(
      mm24h: mm24h,
      mm48h: mm48h,
      mmPerHour: mmPerHour,
      temperature: temperature,
      humidity: humidity,
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
