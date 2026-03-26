import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firestore_paths.dart';
import '../models/user_model.dart';
import '../models/hazard_report_model.dart';
import '../models/alert_model.dart';

/// Centralized Firestore operations for the app.
/// Handles CRUD for users, reports, and alerts.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ──
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection(FirestorePaths.reports);
  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection(FirestorePaths.alerts);

  // ══════════════════════════════════════════════
  //  USER OPERATIONS
  // ══════════════════════════════════════════════

  /// Create or overwrite a user profile document.
  Future<void> setUser(UserModel user) async {
    await _users.doc(user.id).set(user.toJson());
  }

  /// Get a user profile by UID.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson({...doc.data()!, 'id': uid});
  }

  /// Update specific fields on a user profile.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  /// Update user role (admin operation).
  Future<void> setUserRole(String uid, UserRole role) async {
    final roleStr = role.toString().split('.').last;
    await _users.doc(uid).update({'role': roleStr});
  }

  /// Get all users (admin).
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _users.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      return UserModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ══════════════════════════════════════════════
  //  HAZARD REPORT OPERATIONS
  // ══════════════════════════════════════════════

  /// Submit a new hazard report. Returns the document ID.
  Future<String> addReport(HazardReportModel report) async {
    final data = report.toJson();
    data.remove('id'); // let Firestore generate the ID
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _reports.add(data);
    return doc.id;
  }

  /// Update a report document (e.g. to add imageUrls after upload).
  Future<void> updateReport(String reportId, Map<String, dynamic> fields) async {
    await _reports.doc(reportId).update(fields);
  }

  /// Get all reports (admin). Returns newest first.
  Future<List<HazardReportModel>> getAllReports() async {
    final snapshot = await _reports.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Get reports by status (admin filtering).
  Future<List<HazardReportModel>> getReportsByStatus(String status) async {
    final snapshot = await _reports
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Get reports submitted by a specific user.
  Future<List<HazardReportModel>> getUserReports(String userId) async {
    final snapshot = await _reports
        .where('reporterUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Update report status (admin approve/reject/resolve).
  Future<void> updateReportStatus(String reportId, String status) async {
    await _reports.doc(reportId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of all reports, newest first.
  Stream<List<HazardReportModel>> reportsStream({int limit = 50}) {
    return _reports
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
            }).toList());
  }

  // ══════════════════════════════════════════════
  //  ALERT OPERATIONS
  // ══════════════════════════════════════════════

  /// Get active alerts, newest first.
  Future<List<AlertModel>> getAlerts({int limit = 20}) async {
    final snapshot = await _alerts
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      return AlertModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Get alerts for a specific location/city.
  Future<List<AlertModel>> getAlertsForCity(String city, {int limit = 10}) async {
    final snapshot = await _alerts
        .where('location', isGreaterThanOrEqualTo: city)
        .where('location', isLessThanOrEqualTo: '$city\uf8ff')
        .orderBy('location')
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      return AlertModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Add a new alert (admin broadcast).
  Future<String> addAlert(AlertModel alert) async {
    final data = alert.toJson();
    data.remove('id');
    final doc = await _alerts.add(data);
    return doc.id;
  }

  /// Delete an alert.
  Future<void> deleteAlert(String alertId) async {
    await _alerts.doc(alertId).delete();
  }

  /// Stream of alerts for real-time updates.
  Stream<List<AlertModel>> alertsStream({int limit = 20}) {
    return _alerts
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return AlertModel.fromJson({...doc.data(), 'id': doc.id});
            }).toList());
  }

  // ══════════════════════════════════════════════
  //  AQI & WEATHER (written by Cloud Functions)
  // ══════════════════════════════════════════════

  /// Read the latest AQI reading for a city (written by Cloud Functions).
  Future<Map<String, dynamic>?> getAqiReading(String city) async {
    final doc = await _db
        .collection(FirestorePaths.aqiReadings)
        .doc(city.toLowerCase())
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// Read the latest weather data for a city (written by Cloud Functions).
  Future<Map<String, dynamic>?> getWeatherData(String city) async {
    final doc = await _db
        .collection(FirestorePaths.weatherData)
        .doc(city.toLowerCase())
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// Stream AQI data for a city (real-time updates from Cloud Functions).
  Stream<Map<String, dynamic>?> aqiStream(String city) {
    return _db
        .collection(FirestorePaths.aqiReadings)
        .doc(city.toLowerCase())
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // ══════════════════════════════════════════════
  //  FCM TOKEN & ALERT SETTINGS
  // ══════════════════════════════════════════════

  /// Save a user's FCM token.
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection(FirestorePaths.fcmTokens).doc(uid).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a user's FCM token (on logout).
  Future<void> removeFcmToken(String uid) async {
    await _db.collection(FirestorePaths.fcmTokens).doc(uid).delete();
  }

  /// Save alert notification preferences for a user.
  Future<void> saveAlertSettings(String uid, Map<String, dynamic> settings) async {
    await _db
        .collection(FirestorePaths.alertSettings)
        .doc(uid)
        .set(settings, SetOptions(merge: true));
  }

  /// Get alert notification preferences for a user.
  Future<Map<String, dynamic>?> getAlertSettings(String uid) async {
    final doc = await _db
        .collection(FirestorePaths.alertSettings)
        .doc(uid)
        .get();
    return doc.exists ? doc.data() : null;
  }
}
