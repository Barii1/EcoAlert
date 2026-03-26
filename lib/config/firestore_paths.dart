/// Centralized Firestore collection and document path constants.
/// Prevents typos and makes refactoring collection names easy.
class FirestorePaths {
  FirestorePaths._(); // not instantiable

  // ── Top-level collections ──
  static const String users = 'users';
  static const String reports = 'reports';
  static const String alerts = 'alerts';
  static const String aqiReadings = 'aqi_readings';
  static const String weatherData = 'weather_data';
  static const String fcmTokens = 'fcm_tokens';
  static const String alertSettings = 'alert_settings';

  // ── Document helpers ──
  static String userDoc(String uid) => '$users/$uid';
  static String reportDoc(String id) => '$reports/$id';
  static String alertDoc(String id) => '$alerts/$id';
  static String aqiDoc(String city) => '$aqiReadings/${city.toLowerCase()}';
  static String weatherDoc(String city) => '$weatherData/${city.toLowerCase()}';
  static String fcmTokenDoc(String uid) => '$fcmTokens/$uid';
  static String alertSettingsDoc(String uid) => '$alertSettings/$uid';
}
