import 'package:ecoalert/config/api_keys.dart';

const mapboxAccessToken = ApiKeys.mapbox;

class AppConfig {
  static const String waqiToken = ApiKeys.waqi;
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );
  // Backend base URL (override with --dart-define=UPLOAD_API_BASE_URL=...).
  // Android emulator: use http://10.0.2.2:5000 instead of localhost.
  static const String uploadApiBaseUrl = String.fromEnvironment(
    'UPLOAD_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
  static const String defaultCity = 'Lahore';
  static const int refreshIntervalMinutes = 15;
}
