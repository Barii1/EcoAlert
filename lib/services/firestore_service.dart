import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firestore_paths.dart';
import '../models/alert_model.dart';
import '../models/hazard_report_model.dart';
import '../models/user_model.dart';

/// Firestore access: generic helpers (Phases 4–5) plus existing typed CRUD.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Single Document ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getDoc(String path) async {
    final doc = await _db.doc(path).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...?doc.data()};
  }

  Future<String> addDoc(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final ref = await _db.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> setDoc(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _db.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDoc(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _db.doc(path).update(data);
  }

  Future<void> deleteDoc(String path) async {
    await _db.doc(path).delete();
  }

  // ─── Collections ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCollection(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    List<List<dynamic>>? where,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (where != null) {
      for (final condition in where) {
        if (condition.length >= 2) {
          query = query.where(
            condition[0] as String,
            isEqualTo: condition[1],
          );
        }
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> streamCollection(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    String? whereField,
    dynamic whereValue,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (whereField != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<Map<String, dynamic>?> streamDoc(String path) {
    return _db.doc(path).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...?doc.data()};
    });
  }

  // ─── Batch ───────────────────────────────────────────────────

  Future<void> batchWrite(
    List<Map<String, dynamic>> operations,
  ) async {
    final batch = _db.batch();
    for (final op in operations) {
      final type = op['type'] as String;
      final ref = _db.doc(op['path'] as String);
      if (type == 'set') {
        batch.set(ref, op['data'] as Map<String, dynamic>);
      } else if (type == 'update') {
        batch.update(ref, op['data'] as Map<String, dynamic>);
      } else if (type == 'delete') {
        batch.delete(ref);
      }
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════
  //  Typed helpers (used by providers — unchanged API)
  // ══════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection(FirestorePaths.reports);
  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection(FirestorePaths.alerts);

  Future<void> setUser(UserModel user) async {
    await _users.doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson({...doc.data()!, 'id': uid});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  Future<void> setUserRole(String uid, UserRole role) async {
    final roleStr = role.toString().split('.').last;
    await _users.doc(uid).update({'role': roleStr});
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _users.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      return UserModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<String> addReport(HazardReportModel report) async {
    final data = report.toJson();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _reports.add(data);
    return doc.id;
  }

  Future<void> updateReport(String reportId, Map<String, dynamic> fields) async {
    await _reports.doc(reportId).update(fields);
  }

  Future<List<HazardReportModel>> getAllReports() async {
    final snapshot = await _reports.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<List<HazardReportModel>> getReportsByStatus(String status) async {
    final snapshot = await _reports
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<List<HazardReportModel>> getUserReports(String userId) async {
    final snapshot = await _reports
        .where('reporterUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return HazardReportModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _reports.doc(reportId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<HazardReportModel>> reportsStream({int limit = 50}) {
    return _reports
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HazardReportModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  Future<List<AlertModel>> getAlerts({int limit = 20}) async {
    final snapshot = await _alerts
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      return AlertModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

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

  Future<String> addAlert(AlertModel alert) async {
    final data = alert.toJson();
    data.remove('id');
    final doc = await _alerts.add(data);
    return doc.id;
  }

  Future<void> deleteAlert(String alertId) async {
    await _alerts.doc(alertId).delete();
  }

  Stream<List<AlertModel>> alertsStream({int limit = 20}) {
    return _alerts
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AlertModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  Future<Map<String, dynamic>?> getAqiReading(String city) async {
    final doc = await _db
        .collection(FirestorePaths.aqiReadings)
        .doc(city.toLowerCase())
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<Map<String, dynamic>?> getWeatherData(String city) async {
    final doc = await _db
        .collection(FirestorePaths.weatherData)
        .doc(city.toLowerCase())
        .get();
    return doc.exists ? doc.data() : null;
  }

  Stream<Map<String, dynamic>?> aqiStream(String city) {
    return _db
        .collection(FirestorePaths.aqiReadings)
        .doc(city.toLowerCase())
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection(FirestorePaths.fcmTokens).doc(uid).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFcmToken(String uid) async {
    await _db.collection(FirestorePaths.fcmTokens).doc(uid).delete();
  }

  Future<void> saveAlertSettings(String uid, Map<String, dynamic> settings) async {
    await _db
        .collection(FirestorePaths.alertSettings)
        .doc(uid)
        .set(settings, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getAlertSettings(String uid) async {
    final doc = await _db
        .collection(FirestorePaths.alertSettings)
        .doc(uid)
        .get();
    return doc.exists ? doc.data() : null;
  }
}
