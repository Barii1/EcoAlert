import 'dart:math';
import '../models/flood_model.dart';

abstract class WeatherDataSource {
  Future<RainfallData> fetchRainfall(String city);
}

/// Demo implementation. Replace with OpenWeatherMap API in Phase 2.
class DemoWeatherSource implements WeatherDataSource {
  @override
  Future<RainfallData> fetchRainfall(String city) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final rng = Random();
    // Pakistan monsoon season (Jul-Sep) gets higher simulated values
    final month = DateTime.now().month;
    final monsoon = (month >= 7 && month <= 9);
    final base = monsoon ? 45.0 : 8.0;
    return RainfallData(
      mm24h: base + rng.nextDouble() * (monsoon ? 80 : 20),
      mmPerHour: rng.nextDouble() * (monsoon ? 25 : 8),
      mm48h: base * 1.8 + rng.nextDouble() * (monsoon ? 60 : 15),
      timestamp: DateTime.now(),
    );
  }
}
