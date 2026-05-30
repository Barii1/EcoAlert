import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/aqi_model.dart';
import '../config/city_mappings.dart';
import 'aqi_data_source.dart';

/// AQI data source using Open-Meteo air-quality API (lat/lon based).
class OpenMeteoAqiSource implements AqiDataSource {
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
    final coords = _resolveCoords(city, latitude, longitude);

    final response = await _dio.get(
      'https://air-quality-api.open-meteo.com/v1/air-quality',
      queryParameters: {
        'latitude': coords.$1,
        'longitude': coords.$2,
        'hourly':
            'pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,ozone,sulphur_dioxide,carbon_dioxide',
        'current': 'nitrogen_dioxide,pm2_5,pm10,ozone',
        'domains': 'cams_global',
        'timezone': 'auto',
      },
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
    final currentTime = current['time'] as String?;

    final pm25 = (current['pm2_5'] as num?)?.toDouble() ?? 0;
    final pm10 = (current['pm10'] as num?)?.toDouble() ?? 0;
    final no2 = (current['nitrogen_dioxide'] as num?)?.toDouble() ?? 0;
    final so2 = _hourlyValueAtCurrentTime(
      hourly,
      currentTime,
      'sulphur_dioxide',
    );
    final o3 = (current['ozone'] as num?)?.toDouble() ?? 0;
    final co = _hourlyValueAtCurrentTime(
      hourly,
      currentTime,
      'carbon_monoxide',
    );
    final aqiVal = _calculateUsAqi(
      pm25: pm25,
      pm10: pm10,
      no2: no2,
      o3: o3,
      co: co,
    );

    return AqiReading(
      aqi: aqiVal,
      category: AqiReading.categoryFromIndex(aqiVal),
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      so2: so2,
      co: co,
      timestamp: DateTime.now(),
      city: city,
    );
  }

  @override
  Future<List<HourlyAqiPoint>> fetchHourly(
    String city, {
    int hours = 24,
    double? latitude,
    double? longitude,
  }) async {
    final coords = _resolveCoords(city, latitude, longitude);

    try {
      return await _fetchHourlyFromOpenMeteo(coords.$1, coords.$2, hours);
    } catch (e) {
      debugPrint('[OpenMeteoAqiSource] Hourly failed: $e');
      rethrow;
    }
  }

  Future<List<HourlyAqiPoint>> _fetchHourlyFromOpenMeteo(
    double latitude,
    double longitude,
    int hours,
  ) async {
    final response = await _dio.get(
      'https://air-quality-api.open-meteo.com/v1/air-quality',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'hourly':
            'pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,ozone,sulphur_dioxide,carbon_dioxide',
        'past_hours': 0,
        'forecast_hours': hours,
        'domains': 'cams_global',
        'timezone': 'auto',
      },
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final pm25Values = (hourly['pm2_5'] as List<dynamic>?) ?? [];
    final pm10Values = (hourly['pm10'] as List<dynamic>?) ?? [];
    final coValues = (hourly['carbon_monoxide'] as List<dynamic>?) ?? [];
    final no2Values = (hourly['nitrogen_dioxide'] as List<dynamic>?) ?? [];
    final o3Values = (hourly['ozone'] as List<dynamic>?) ?? [];

    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final points = <HourlyAqiPoint>[];

    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.tryParse(times[i]);
      if (dt == null || dt.isBefore(cutoff)) continue;
      final aqiVal = _calculateUsAqi(
        pm25: _listValue(pm25Values, i),
        pm10: _listValue(pm10Values, i),
        no2: _listValue(no2Values, i),
        o3: _listValue(o3Values, i),
        co: _listValue(coValues, i),
      );
      points.add(HourlyAqiPoint(hour: dt, aqi: aqiVal));
    }

    if (points.isEmpty) {
      throw Exception('No hourly AQI data returned from Open-Meteo');
    }
    return points;
  }

  (double, double) _resolveCoords(
    String city,
    double? latitude,
    double? longitude,
  ) {
    if (latitude != null && longitude != null) {
      return (latitude, longitude);
    }
    final coords = CityMappings.cityCoords[city] ??
        CityMappings.cityCoords.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == city.toLowerCase(),
              orElse: () => const MapEntry('Lahore', [31.5204, 74.3587]),
            )
            .value;
    return (coords[0], coords[1]);
  }

  double _latestHourlyValue(dynamic rawValues) {
    final values = rawValues is List<dynamic> ? rawValues : const [];
    for (final value in values.reversed) {
      if (value is num) return value.toDouble();
    }
    return 0;
  }

  double _hourlyValueAtCurrentTime(
    Map<String, dynamic> hourly,
    String? currentTime,
    String key,
  ) {
    final times = (hourly['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = (hourly[key] as List<dynamic>?) ?? [];
    final index = currentTime == null ? -1 : times.indexOf(currentTime);
    if (index >= 0) return _listValue(values, index);
    return _latestHourlyValue(values);
  }

  double _listValue(List<dynamic> values, int index) {
    if (index < 0 || index >= values.length) return 0;
    return (values[index] as num?)?.toDouble() ?? 0;
  }

  int _calculateUsAqi({
    required double pm25,
    required double pm10,
    required double no2,
    required double o3,
    required double co,
  }) {
    final candidates = <int>[
      _breakpointAqi(pm25, const [
        _AqiBreakpoint(0.0, 12.0, 0, 50),
        _AqiBreakpoint(12.1, 35.4, 51, 100),
        _AqiBreakpoint(35.5, 55.4, 101, 150),
        _AqiBreakpoint(55.5, 150.4, 151, 200),
        _AqiBreakpoint(150.5, 250.4, 201, 300),
        _AqiBreakpoint(250.5, 500.4, 301, 500),
      ]),
      _breakpointAqi(pm10, const [
        _AqiBreakpoint(0, 54, 0, 50),
        _AqiBreakpoint(55, 154, 51, 100),
        _AqiBreakpoint(155, 254, 101, 150),
        _AqiBreakpoint(255, 354, 151, 200),
        _AqiBreakpoint(355, 424, 201, 300),
        _AqiBreakpoint(425, 604, 301, 500),
      ]),
      // Open-Meteo gases are ug/m3. Convert approximately to EPA units.
      _breakpointAqi((o3 / 1.96) / 1000, const [
        _AqiBreakpoint(0.000, 0.054, 0, 50),
        _AqiBreakpoint(0.055, 0.070, 51, 100),
        _AqiBreakpoint(0.071, 0.085, 101, 150),
        _AqiBreakpoint(0.086, 0.105, 151, 200),
        _AqiBreakpoint(0.106, 0.200, 201, 300),
      ]),
      _breakpointAqi(no2 / 1.88, const [
        _AqiBreakpoint(0, 53, 0, 50),
        _AqiBreakpoint(54, 100, 51, 100),
        _AqiBreakpoint(101, 360, 101, 150),
        _AqiBreakpoint(361, 649, 151, 200),
        _AqiBreakpoint(650, 1249, 201, 300),
        _AqiBreakpoint(1250, 2049, 301, 500),
      ]),
      _breakpointAqi(co / 1145, const [
        _AqiBreakpoint(0.0, 4.4, 0, 50),
        _AqiBreakpoint(4.5, 9.4, 51, 100),
        _AqiBreakpoint(9.5, 12.4, 101, 150),
        _AqiBreakpoint(12.5, 15.4, 151, 200),
        _AqiBreakpoint(15.5, 30.4, 201, 300),
        _AqiBreakpoint(30.5, 50.4, 301, 500),
      ]),
    ];
    return candidates.reduce((a, b) => a > b ? a : b).clamp(0, 500).toInt();
  }

  int _breakpointAqi(double value, List<_AqiBreakpoint> breakpoints) {
    if (value <= 0) return 0;
    final matches = breakpoints.where((b) => value >= b.low && value <= b.high);
    final breakpoint = matches.isNotEmpty ? matches.first : breakpoints.last;
    final aqi = ((breakpoint.indexHigh - breakpoint.indexLow) /
                (breakpoint.high - breakpoint.low)) *
            (value - breakpoint.low) +
        breakpoint.indexLow;
    return aqi.round();
  }
}

class _AqiBreakpoint {
  const _AqiBreakpoint(
    this.low,
    this.high,
    this.indexLow,
    this.indexHigh,
  );

  final double low;
  final double high;
  final int indexLow;
  final int indexHigh;
}
