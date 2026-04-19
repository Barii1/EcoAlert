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
  Future<AqiReading> fetchCurrent(String city) async {
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
      co: _extractPollutant(iaqi, 'co'),
      timestamp: DateTime.now(),
      city: cityName,
    );
  }

  @override
  Future<List<HourlyAqiPoint>> fetchHourly(String city, {int hours = 24}) async {
    // WAQI free tier doesn't provide hourly history directly.
    // Generate synthetic hourly points based on current AQI with realistic variance.
    // Cloud Functions will provide real hourly data via Firestore in Phase 6.
    try {
      final current = await fetchCurrent(city);
      final now = DateTime.now();
      final points = <HourlyAqiPoint>[];

      for (int i = hours - 1; i >= 0; i--) {
        // Simulate diurnal AQI pattern: worse in morning/evening, better midday.
        final hour = (now.hour - i) % 24;
        final diurnalFactor = _diurnalFactor(hour);
        final variance = (current.aqi * 0.15 * diurnalFactor).round();
        final hourAqi = (current.aqi + variance).clamp(0, 500);

        points.add(HourlyAqiPoint(
          hour: now.subtract(Duration(hours: i)),
          aqi: hourAqi,
        ));
      }

      return points;
    } catch (e) {
      debugPrint('[WaqiAqiSource] fetchHourly fallback: $e');
      rethrow;
    }
  }

  double _extractPollutant(Map<String, dynamic> iaqi, String key) {
    final entry = iaqi[key];
    if (entry is Map<String, dynamic>) {
      return (entry['v'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  /// Returns a factor (-1 to 1) simulating diurnal AQI variation.
  /// Peaks at 7-9 AM and 6-8 PM (rush hours), dips midday.
  double _diurnalFactor(int hour) {
    if (hour >= 7 && hour <= 9) return 0.8;
    if (hour >= 18 && hour <= 20) return 0.6;
    if (hour >= 12 && hour <= 15) return -0.5;
    if (hour >= 1 && hour <= 5) return -0.3;
    return 0.0;
  }
}
