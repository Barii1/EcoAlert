import 'package:ecoalert/config/api_keys.dart';

const mapboxAccessToken = ApiKeys.mapbox;

class AppConfig {
  static const String waqiToken = ApiKeys.waqi;
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );
  static const String uploadApiBaseUrl = String.fromEnvironment(
    'UPLOAD_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  static const String defaultCity = 'lahore';
  static const int refreshIntervalMinutes = 15;
}
