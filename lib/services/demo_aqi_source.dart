import 'dart:math';
import '../models/aqi_model.dart';
import 'aqi_data_source.dart';

/// Demo implementation — returns realistic but randomised AQI data for Pakistan cities.
/// Replace with a real API implementation (WAQI, OpenWeather, IQAir) later.
class DemoAqiSource implements AqiDataSource {
  static final Map<String, int> _baselines = {
    'Lahore': 210,
    'Karachi': 145,
    'Islamabad': 95,
    'Peshawar': 175,
    'Multan': 190,
    'Faisalabad': 165,
  };

  @override
  Future<AqiReading> fetchCurrent(String city) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final rng = Random();
    final base = _baselines[city] ?? 150;
    final aqi = (base + rng.nextInt(40) - 20).clamp(0, 500);
    final category = AqiReading.categoryFromIndex(aqi);
    return AqiReading(
      aqi: aqi,
      category: category,
      pm25: aqi * 0.6 + rng.nextDouble() * 10,
      pm10: aqi * 0.9 + rng.nextDouble() * 15,
      o3: 30 + rng.nextDouble() * 20,
      no2: 20 + rng.nextDouble() * 30,
      co: 1.2 + rng.nextDouble() * 0.8,
      timestamp: DateTime.now(),
      city: city,
    );
  }

  @override
  Future<List<HourlyAqiPoint>> fetchHourly(String city, {int hours = 24}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final rng = Random();
    final base = _baselines[city] ?? 150;
    return List.generate(hours, (i) {
      final hour = DateTime.now().subtract(Duration(hours: hours - 1 - i));
      final aqi = (base + rng.nextInt(60) - 30).clamp(0, 500);
      return HourlyAqiPoint(hour: hour, aqi: aqi);
    });
  }
}
