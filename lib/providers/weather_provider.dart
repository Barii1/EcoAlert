import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../config/city_mappings.dart';

/// Provides current weather conditions via Open-Meteo API (free, no key).
class WeatherProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  WeatherCondition? _current;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _city = 'Lahore';

  WeatherCondition? get current => _current;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get city => _city;

  Future<void> loadForCity(String city) async {
    _city = city;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final coords = CityMappings.cityCoords[city];
      if (coords == null) throw Exception('No coordinates for $city');

      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': coords[0],
          'longitude': coords[1],
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'relative_humidity_2m',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
            'surface_pressure',
          ].join(','),
          'daily': 'temperature_2m_max,temperature_2m_min',
          'timezone': 'auto',
          'forecast_days': 1,
        },
      );

      _current = WeatherCondition.fromOpenMeteo(response.data, city);
      debugPrint('[Weather] $city: ${_current!.temperature}°C, ${_current!.description}');
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not load weather data.';
      debugPrint('[Weather] Failed for $city: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => loadForCity(_city);
}
