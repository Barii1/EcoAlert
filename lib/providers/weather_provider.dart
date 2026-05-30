import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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
  Position? _position;

  WeatherCondition? get current => _current;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get city => _city;
  Position? get position => _position;

  Future<void> loadForCity(String city) async {
    _city = city;
    _position = null;
    return _load(city: city);
  }

  Future<void> loadForLocation(
    Position position, {
    String? cityLabel,
  }) async {
    _position = position;
    _city = cityLabel ?? _city;
    return _load(
      city: _city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _load({
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final coords = _resolveCoords(city, latitude, longitude);

      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': coords.$1,
          'longitude': coords.$2,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'relative_humidity_2m',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
            'surface_pressure',
          ].join(','),
          'hourly': 'temperature_2m,weather_code',
          'daily':
              'temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max',
          'timezone': 'auto',
          'forecast_days': 3,
        },
      );

      _current = WeatherCondition.fromOpenMeteo(response.data, city);
      debugPrint(
          '[Weather] $city: ${_current!.temperature}°C, ${_current!.description}');
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not load weather data.';
      debugPrint('[Weather] Failed for $city: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() {
    if (_position != null) {
      return loadForLocation(_position!, cityLabel: _city);
    }
    return loadForCity(_city);
  }

  (double, double) _resolveCoords(
    String city,
    double? latitude,
    double? longitude,
  ) {
    if (latitude != null && longitude != null) {
      return (latitude, longitude);
    }

    final normalizedCity = city.trim();
    List<double>? coords = CityMappings.cityCoords[normalizedCity];
    coords ??= CityMappings.cityCoords.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == normalizedCity.toLowerCase(),
          orElse: () => const MapEntry('', <double>[]),
        )
        .value;
    if (coords.isEmpty) {
      throw Exception('No coordinates for $city');
    }
    return (coords[0], coords[1]);
  }
}
