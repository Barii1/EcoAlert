import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/hazard_report_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({
    FirestoreService? firestoreService,
    StorageService? storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  final FirestoreService? _firestoreService;
  final StorageService? _storageService;
  StreamSubscription? _reportsSub;

  List<HazardReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HazardReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<HazardReportModel> get pendingReports =>
      _reports.where((r) => r.status == ReportStatus.pending).toList(growable: false);

  int get pendingCount => pendingReports.length;

  /// Initialize: subscribe to Firestore real-time stream.
  Future<void> init() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    _reportsSub = _firestoreService!.reportsStream().listen(
      (reports) {
        _reports = reports;
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
      reporterUid: reporterUid,
      reporterName: reporterName,
    );

    if (_firestoreService == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final docId = await _firestoreService!.addReport(report);

      // Upload images to Firebase Storage, then update Firestore doc with URLs.
      if (images != null && images.isNotEmpty && _storageService != null) {
        final urls = await _storageService!.uploadReportImages(
          reportId: docId,
          images: images,
        );
        if (urls.isNotEmpty) {
          await _firestoreService!.updateReport(docId, {
            'imageUrls': urls,
            'imageCount': urls.length,
          });
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to submit report: $e';
      _isLoading = false;
      notifyListeners();
    }
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
    if (_firestoreService == null) return;
    try {
      await _firestoreService!.updateReportStatus(reportId, status.name);
    } catch (e) {
      _errorMessage = 'Failed to update report: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    super.dispose();
  }
}
