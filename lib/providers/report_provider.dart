import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_tables.dart';
import '../models/hazard_report_model.dart';
import '../services/supabase_service.dart';
import '../services/upload_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService? _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _reportsSubscription;

  List<HazardReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _pendingWrite = false; // suppresses stream re-emissions during in-flight writes

  List<HazardReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<HazardReportModel> get pendingReports =>
      _reports.where((r) => r.status == ReportStatus.pending).toList(growable: false);

  int get pendingCount => pendingReports.length;

  Future<void> init({bool isAdmin = false, String? uid}) async {
    if (_supabaseService == null) {
      _reports = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    _startStream(isAdmin: isAdmin, uid: uid);
  }

  void _startStream({required bool isAdmin, String? uid}) {
    if (_supabaseService == null) return;
    if (!isAdmin && (uid == null || uid.isEmpty)) {
      _reports = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _reportsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _reportsSubscription = _supabaseService!
        .streamTable(
          SupabaseTables.reports,
          primaryKeys: ['id'],
          orderBy: 'created_at',
          descending: true,
          limit: 100,
          whereField: isAdmin ? null : 'reporter_uid',
          whereValue: isAdmin ? null : uid,
        )
        .listen(
          (rows) {
            // Skip re-emission while an optimistic write is in flight — prevents
            // the stream from overwriting local state before the DB commits.
            if (_pendingWrite) return;
            _reports = rows.map((r) => HazardReportModel.fromJson(r)).toList();
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

  Future<bool> addReport({
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
    if (_supabaseService == null) {
      _errorMessage = 'Sign in to submit hazard reports.';
      notifyListeners();
      return false;
    }

    final supaUser = Supabase.instance.client.auth.currentUser;
    final uid = (supaUser?.id.isNotEmpty == true) ? supaUser!.id : reporterUid;
    final name = reporterName.isNotEmpty
        ? reporterName
        : (supaUser?.email?.split('@').first ?? 'User');

    final report = HazardReportModel(
      id: '',
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

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'hazard_type': report.hazardType,
        'details': report.details,
        'image_count': report.imageCount,
        'location_label': report.locationLabel,
        'status': report.status.name,
        'aqi': report.aqi,
        'main_pollutant': report.mainPollutant,
        'confidence': report.confidence,
        'reporter_uid': report.reporterUid,
        'reporter_name': report.reporterName,
        'image_urls': <String>[],
      };

      // Step 1: save report text — this must succeed
      final newId = await _supabaseService!.insertRow(SupabaseTables.reports, data);

      // Step 2: upload images — optional; a storage RLS failure won't kill the submission
      if (images != null && images.isNotEmpty) {
        try {
          final urls = await UploadService.uploadReportImages(
            reportId: newId,
            uid: uid,
            images: images,
          );
          await _supabaseService!.updateRow(
            SupabaseTables.reports,
            newId,
            {'image_urls': urls, 'image_count': urls.length},
          );
        } catch (uploadErr) {
          // Report saved, images failed — surface a non-fatal warning
          _errorMessage =
              'Report submitted, but images could not be uploaded ($uploadErr). '
              'Enable storage RLS in Supabase: allow INSERT on bucket "report-images".';
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> approve(String reportId) => _setStatus(reportId, ReportStatus.approved);
  Future<void> reject(String reportId) => _setStatus(reportId, ReportStatus.rejected);
  Future<void> resolve(String reportId) => _setStatus(reportId, ReportStatus.resolved);

  Future<void> _setStatus(String reportId, ReportStatus status) async {
    if (_supabaseService == null) return;

    final idx = _reports.indexWhere((r) => r.id == reportId);
    final original = idx >= 0 ? _reports[idx] : null;

    // Optimistic update + suppress stream re-emissions until the write lands
    _pendingWrite = true;
    if (idx >= 0) {
      _reports = List.of(_reports)..[idx] = original!.copyWith(status: status);
      notifyListeners();
    }

    try {
      await _supabaseService!.updateRow(
        SupabaseTables.reports,
        reportId,
        {'status': status.name},
      );
    } catch (e) {
      if (idx >= 0 && original != null) {
        _reports = List.of(_reports)..[idx] = original;
      }
      _errorMessage = 'Failed to update report: $e';
      notifyListeners();
    } finally {
      _pendingWrite = false;
    }
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
}
