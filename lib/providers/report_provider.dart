import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/firestore_paths.dart';
import '../models/hazard_report_model.dart';
import '../services/firestore_service.dart';
import '../services/upload_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService? _firestoreService;
  StreamSubscription<List<Map<String, dynamic>>>? _reportsSubscription;
  bool _isUsingFirebase = false;

  List<HazardReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HazardReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<HazardReportModel> get pendingReports =>
      _reports.where((r) => r.status == ReportStatus.pending).toList(growable: false);

  int get pendingCount => pendingReports.length;

  /// Local demo baseline (no Firestore subscription).
  Future<void> init() async {
    if (_isUsingFirebase) return;
    _reports = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Call after Firebase login to stream real reports.
  void initFirestore({required bool isAdmin, String? uid}) {
    if (_firestoreService == null) return;

    _isUsingFirebase = true;
    _reportsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!isAdmin && (uid == null || uid.isEmpty)) {
      _reports = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final Stream<List<Map<String, dynamic>>> stream = isAdmin
        ? _firestoreService!.streamCollection(
            FirestorePaths.reports,
            orderBy: 'createdAt',
            descending: true,
            limit: 100,
          )
        : _firestoreService!.streamCollection(
            FirestorePaths.reports,
            whereField: 'reporterUid',
            whereValue: uid,
          );

    _reportsSubscription = stream.listen(
      (data) {
        var models =
            data.map((row) => HazardReportModel.fromJson(row)).toList();
        if (!isAdmin) {
          models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (models.length > 100) {
            models = models.sublist(0, 100);
          }
        }
        _reports = models;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Error streaming reports: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop Firestore and revert to empty demo list.
  void disposeFirestore() {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
    _isUsingFirebase = false;
    _reports = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Submit a new hazard report.
  Future<void> addReport({
    required String hazardType,
    required String details,
    required int imageCount,
    required String locationLabel,
    String reporterUid = '',
    String reporterName = '',
    List<File>? images,
    int? aqi,
    String? mainPollutant,
    double? confidence,
  }) async {
    final fbUid = FirebaseAuth.instance.currentUser?.uid;
    final uid = (fbUid != null && fbUid.isNotEmpty) ? fbUid : reporterUid;
    final fbName = FirebaseAuth.instance.currentUser?.displayName;
    final name = reporterName.isNotEmpty
        ? reporterName
        : (fbName != null && fbName.isNotEmpty ? fbName : 'User');

    final report = HazardReportModel(
      id: 'r-${DateTime.now().millisecondsSinceEpoch}',
      hazardType: hazardType,
      details: details,
      imageCount: imageCount,
      locationLabel: locationLabel,
      createdAt: DateTime.now(),
      status: ReportStatus.pending,
      aqi: aqi ?? 0,
      mainPollutant: mainPollutant ?? '',
      confidence: confidence ?? 0,
      reporterUid: uid,
      reporterName: name,
      imageUrls: const [],
    );

    if (_isUsingFirebase) {
      if (_firestoreService == null) return;
      try {
        _isLoading = true;
        notifyListeners();

        final data = report.toJson()
          ..remove('id')
          ..remove('createdAt');
        final newDocId =
            await _firestoreService!.addDoc(FirestorePaths.reports, data);

        // Upload images if any were provided
        if (images != null && images.isNotEmpty) {
          final urls = await UploadService.uploadReportImages(
            reportId: newDocId,
            images: images,
          );
          if (urls.isNotEmpty) {
            await _firestoreService!.updateDoc(
              FirestorePaths.reportDoc(newDocId),
              {
                'imageUrls': urls,
                'imageCount': urls.length,
              },
            );
          }
        }

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to submit report: $e';
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // Demo mode — persist in memory only (no Firestore).
    _isLoading = true;
    notifyListeners();
    _reports = [..._reports, report];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> approve(String reportId) async {
    await _setStatus(reportId, ReportStatus.approved);
  }

  Future<void> reject(String reportId) async {
    await _setStatus(reportId, ReportStatus.rejected);
  }

  Future<void> resolve(String reportId) async {
    await _setStatus(reportId, ReportStatus.resolved);
  }

  Future<void> _setStatus(String reportId, ReportStatus status) async {
    if (_isUsingFirebase) {
      if (_firestoreService == null) return;
      try {
        await _firestoreService!.updateDoc(
          FirestorePaths.reportDoc(reportId),
          {'status': status.name},
        );
      } catch (e) {
        _errorMessage = 'Failed to update report: $e';
        notifyListeners();
      }
      return;
    }

    // Demo mode — update local list only.
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx == -1) return;
    _reports = [
      ..._reports.sublist(0, idx),
      _reports[idx].copyWith(status: status),
      ..._reports.sublist(idx + 1),
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
}
