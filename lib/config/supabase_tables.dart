/// Supabase table name constants — replaces firestore_paths.dart.
class SupabaseTables {
  // Core data tables
  static const String profiles       = 'profiles';
  static const String alerts         = 'alerts';
  static const String reports        = 'reports';
  static const String hazardZones    = 'hazard_zones';
  static const String communityPosts = 'community_posts';

  // Sensor / cache tables (written by Python backend, read-only for Flutter)
  static const String aqiReadings    = 'aqi_readings';
  static const String weatherData    = 'weather_data';

  // Per-user settings tables
  static const String alertSettings  = 'alert_settings';
  static const String fcmTokens      = 'fcm_tokens';

  // Admin / audit tables
  static const String adminLogs      = 'admin_logs';
  static const String predictionLogs = 'prediction_logs';

  // Storage bucket names (used with Supabase.instance.client.storage)
  static const String bucketReportImages    = 'report-images';
  static const String bucketProfilePictures = 'profile-pictures';
}
