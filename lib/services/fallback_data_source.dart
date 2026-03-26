import 'package:flutter/foundation.dart';
import '../models/aqi_model.dart';
import '../models/flood_model.dart';
import 'aqi_data_source.dart';
import 'demo_weather_source.dart'; // for WeatherDataSource abstract

/// Wraps a real data source and falls back to a demo source on failure.
/// This ensures the app always shows data — real when online, demo when offline.

class FallbackAqiSource implements AqiDataSource {
  FallbackAqiSource({required this.real, required this.fallback});

  final AqiDataSource real;
  final AqiDataSource fallback;

  @override
  Future<AqiReading> fetchCurrent(String city) async {
    try {
      final result = await real.fetchCurrent(city);
      debugPrint('[AQI] Using real data for $city (AQI: ${result.aqi})');
      return result;
    } catch (e) {
      debugPrint('[AQI] Real API failed for $city, using demo fallback: $e');
      return fallback.fetchCurrent(city);
    }
  }

  @override
  Future<List<HourlyAqiPoint>> fetchHourly(String city, {int hours = 24}) async {
    try {
      return await real.fetchHourly(city, hours: hours);
    } catch (e) {
      debugPrint('[AQI] Real hourly API failed for $city, using demo fallback: $e');
      return fallback.fetchHourly(city, hours: hours);
    }
  }
}

class FallbackWeatherSource implements WeatherDataSource {
  FallbackWeatherSource({required this.real, required this.fallback});

  final WeatherDataSource real;
  final WeatherDataSource fallback;

  @override
  Future<RainfallData> fetchRainfall(String city) async {
    try {
      final result = await real.fetchRainfall(city);
      debugPrint('[Weather] Using real data for $city (24h: ${result.mm24h}mm)');
      return result;
    } catch (e) {
      debugPrint('[Weather] Real API failed for $city, using demo fallback: $e');
      return fallback.fetchRainfall(city);
    }
  }
}
