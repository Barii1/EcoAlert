import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ReportStatus { pending, approved, rejected, resolved }

@immutable
class HazardReportModel {
  const HazardReportModel({
    required this.id,
    required this.hazardType,
    required this.details,
    required this.imageCount,
    required this.locationLabel,
    required this.createdAt,
    required this.status,
    required this.aqi,
    required this.mainPollutant,
    required this.confidence,
    this.reporterUid = '',
    this.reporterName = '',
    this.imageUrls = const [],
  });

  final String id;
  final String hazardType;
  final String details;
  final int imageCount;
  final String locationLabel;
  final DateTime createdAt;
  final ReportStatus status;

  // Hard-coded "AI inference" fields for demo.
  final int aqi;
  final String mainPollutant;
  final double confidence;

  // Backend fields
  final String reporterUid;
  final String reporterName;
  final List<String> imageUrls;

  factory HazardReportModel.fromJson(Map<String, dynamic> json) {
    return HazardReportModel(
      id: json['id'] as String? ?? '',
      hazardType: json['hazardType'] as String? ?? '',
      details: json['details'] as String? ?? '',
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      locationLabel: json['locationLabel'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      status: ReportStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      aqi: (json['aqi'] as num?)?.toInt() ?? 0,
      mainPollutant: json['mainPollutant'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reporterUid: json['reporterUid'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hazardType': hazardType,
        'details': details,
        'imageCount': imageCount,
        'locationLabel': locationLabel,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'aqi': aqi,
        'mainPollutant': mainPollutant,
        'confidence': confidence,
        'reporterUid': reporterUid,
        'reporterName': reporterName,
        'imageUrls': imageUrls,
      };

  HazardReportModel copyWith({
    ReportStatus? status,
    List<String>? imageUrls,
    String? reporterUid,
    String? reporterName,
    int? imageCount,
  }) {
    return HazardReportModel(
      id: id,
      hazardType: hazardType,
      details: details,
      imageCount: imageCount ?? this.imageCount,
      locationLabel: locationLabel,
      createdAt: createdAt,
      status: status ?? this.status,
      aqi: aqi,
      mainPollutant: mainPollutant,
      confidence: confidence,
      reporterUid: reporterUid ?? this.reporterUid,
      reporterName: reporterName ?? this.reporterName,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  /// Parse DateTime from ISO string, Firestore Timestamp, or fallback to now.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
