/// Centralized Firestore collection and document path constants.
class FirestorePaths {
  static const String users = 'users';
  static const String alerts = 'alerts';
  static const String reports = 'reports';
  static const String environmentalSnapshots = 'environmental_snapshots';
  static const String communityPosts = 'community_posts';
  static const String adminLogs = 'admin_logs';

  /// Legacy / auxiliary collections (FCM, settings, cached env data).
  static const String aqiReadings = 'aqi_readings';
  static const String weatherData = 'weather_data';
  static const String fcmTokens = 'fcm_tokens';
  static const String alertSettings = 'alert_settings';

  static String userDoc(String uid) => 'users/$uid';
  static String alertDoc(String id) => 'alerts/$id';
  static String reportDoc(String id) => 'reports/$id';
  static String aqiDoc(String city) => '$aqiReadings/${city.toLowerCase()}';
  static String weatherDoc(String city) => '$weatherData/${city.toLowerCase()}';
  static String fcmTokenDoc(String uid) => '$fcmTokens/$uid';
  static String alertSettingsDoc(String uid) => '$alertSettings/$uid';
}
