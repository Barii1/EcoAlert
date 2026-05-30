import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/aqi_model.dart';
import '../config/app_config.dart';
import '../config/city_mappings.dart';
import 'aqi_data_source.dart';

/// Real AQI data source using the World Air Quality Index (WAQI) API.
/// API docs: https://aqicn.org/json-api/doc/
class WaqiAqiSource implements AqiDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  Future<AqiReading> fetchCurrent(
    String city, {
    double? latitude,
    double? longitude,
  }) async {
    if (AppConfig.waqiToken.isEmpty) {
      throw Exception('WAQI API token is not configured.');
    }
    final station = CityMappings.getWaqiStation(city);
    final url =
        'https://api.waqi.info/feed/$station/?token=${AppConfig.waqiToken}';

    final response = await _dio.get(url);
    final data = response.data as Map<String, dynamic>? ?? {};

    if (data['status'] != 'ok') {
      throw Exception('WAQI API error: ${data['data'] ?? 'Unknown error'}');
    }

    final feed = data['data'] as Map<String, dynamic>? ?? {};
    final aqiVal = (feed['aqi'] as num?)?.toInt() ?? 0;
    final iaqi = feed['iaqi'] as Map<String, dynamic>? ?? {};
    final cityName = (feed['city'] is Map<String, dynamic>)
        ? (feed['city']['name'] as String? ?? city)
        : city;

    return AqiReading(
      aqi: aqiVal,
      category: AqiReading.categoryFromIndex(aqiVal),
      pm25: _extractPollutant(iaqi, 'pm25'),
      pm10: _extractPollutant(iaqi, 'pm10'),
      o3: _extractPollutant(iaqi, 'o3'),
      no2: _extractPollutant(iaqi, 'no2'),
      so2: _extractPollutant(iaqi, 'so2'),
      co: _extractPollutant(iaqi, 'co'),
      timestamp: DateTime.now(),
      city: cityName,
    );
  }

  @override
  Future<List<HourlyAqiPoint>> fetchHourly(
    String city, {
    int hours = 24,
    double? latitude,
    double? longitude,
  }) async {
    try {
      return await _fetchHourlyFromOpenMeteo(city, hours);
    } catch (e) {
      debugPrint(
          '[WaqiAqiSource] Open-Meteo hourly failed: $e — using synthetic fallback');
      try {
        final current = await fetchCurrent(
          city,
          latitude: latitude,
          longitude: longitude,
        );
        return _syntheticHourly(current, hours);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<List<HourlyAqiPoint>> _fetchHourlyFromOpenMeteo(
      String city, int hours) async {
    final coords = CityMappings.cityCoords[city] ??
        CityMappings.cityCoords.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == city.toLowerCase(),
              orElse: () => const MapEntry('Lahore', [31.5204, 74.3587]),
            )
            .value;

    final response = await _dio.get(
      'https://air-quality-api.open-meteo.com/v1/air-quality',
      queryParameters: {
        'latitude': coords[0],
        'longitude': coords[1],
        'hourly': 'us_aqi',
        'timezone': 'auto',
        'past_days': 1,
        'forecast_days': 0,
      },
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final aqiValues = (hourly['us_aqi'] as List<dynamic>?) ?? [];

    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final points = <HourlyAqiPoint>[];

    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.tryParse(times[i]);
      if (dt == null || dt.isBefore(cutoff)) continue;
      final aqiVal = (aqiValues[i] as num?)?.toInt() ?? 0;
      points.add(HourlyAqiPoint(hour: dt, aqi: aqiVal));
    }

    if (points.isEmpty) {
      throw Exception('No hourly AQI data returned from Open-Meteo');
    }
    return points;
  }

  List<HourlyAqiPoint> _syntheticHourly(AqiReading current, int hours) {
    final now = DateTime.now();
    return List.generate(hours, (i) {
      final hour = (now.hour - (hours - 1 - i)) % 24;
      final factor = _diurnalFactor(hour);
      final variance = (current.aqi * 0.15 * factor).round();
      return HourlyAqiPoint(
        hour: now.subtract(Duration(hours: hours - 1 - i)),
        aqi: (current.aqi + variance).clamp(0, 500),
      );
    });
  }

  double _extractPollutant(Map<String, dynamic> iaqi, String key) {
    final entry = iaqi[key];
    if (entry is Map<String, dynamic>) {
      return (entry['v'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  double _diurnalFactor(int hour) {
    if (hour >= 7 && hour <= 9) return 0.8;
    if (hour >= 18 && hour <= 20) return 0.6;
    if (hour >= 12 && hour <= 15) return -0.5;
    if (hour >= 1 && hour <= 5) return -0.3;
    return 0.0;
  }
}
