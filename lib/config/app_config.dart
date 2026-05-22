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
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xwpgaujwuyopbltwuose.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3cGdhdWp3dXlvcGJsdHd1b3NlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MDkyMzIsImV4cCI6MjA5MjA4NTIzMn0.MoyyjW676rQ19Sc3itd5faEAaQWQlplR3iiJNM1N7Rs',
  );
  static const String supabaseReportBucket = String.fromEnvironment(
    'SUPABASE_REPORT_BUCKET',
    defaultValue: 'report-images',
  );
  static const String supabaseProfileBucket = String.fromEnvironment(
    'SUPABASE_PROFILE_BUCKET',
    defaultValue: 'profile-images',
  );
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static const String defaultCity = 'Lahore';
  static const int refreshIntervalMinutes = 15;
  static const String premiumPriceLabel = 'PKR 499 / month';
  static const int alertMaxAgeDays = 14;
}
