import 'package:ecoalert/config/api_keys.dart';

const mapboxAccessToken = ApiKeys.mapbox;

class AppConfig {
  static const String waqiToken = ApiKeys.waqi;
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );
  // ── PRODUCTION URL ────────────────────────────────────────────────────────
  // After deploying to Railway, paste your URL here as the defaultValue.
  // Example: 'https://ecoalert-backend-production.up.railway.app'
  // For local Android emulator testing keep: 'http://10.0.2.2:5000'
  // For physical device on same WiFi use: 'http://192.168.1.15:5000'
  static const String uploadApiBaseUrl = String.fromEnvironment(
    'UPLOAD_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',   // ← REPLACE THIS after Railway deploy
  );
  static const String defaultCity = 'lahore';
  static const int refreshIntervalMinutes = 15;
}
