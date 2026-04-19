import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FloodRiskLevel { low, moderate, high, critical }

DateTime? _floodDateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class RainfallData {
  final double mm24h;       // Rainfall in last 24 hours (mm)
  final double mmPerHour;   // Current intensity (mm/hr)
  final double mm48h;       // Rainfall in last 48 hours
  final DateTime timestamp;
  const RainfallData({required this.mm24h, required this.mmPerHour, required this.mm48h, required this.timestamp});

  factory RainfallData.fromJson(Map<String, dynamic> json) {
    return RainfallData(
      mm24h: (json['mm24h'] as num).toDouble(),
      mmPerHour: (json['mmPerHour'] as num).toDouble(),
      mm48h: (json['mm48h'] as num).toDouble(),
      timestamp: _floodDateTimeFromJson(json['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mm24h': mm24h,
        'mmPerHour': mmPerHour,
        'mm48h': mm48h,
        'timestamp': timestamp.toIso8601String(),
      };
}

class FloodRisk {
  final int riskScore;         // 0-100
  final FloodRiskLevel level;
  final RainfallData rainfall;
  final String city;
  final List<String> affectedAreas;
  final String explanation;
  final DateTime calculatedAt;

  const FloodRisk({
    required this.riskScore,
    required this.level,
    required this.rainfall,
    required this.city,
    required this.affectedAreas,
    required this.explanation,
    required this.calculatedAt,
  });

  factory FloodRisk.fromJson(Map<String, dynamic> json) {
    return FloodRisk(
      riskScore: (json['riskScore'] as num).toInt(),
      level: FloodRiskLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => FloodRiskLevel.low,
      ),
      rainfall: RainfallData.fromJson(json['rainfall'] as Map<String, dynamic>),
      city: json['city'] as String,
      affectedAreas: List<String>.from(json['affectedAreas'] ?? []),
      explanation: json['explanation'] as String? ?? '',
      calculatedAt:
          _floodDateTimeFromJson(json['calculatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'riskScore': riskScore,
        'level': level.name,
        'rainfall': rainfall.toJson(),
        'city': city,
        'affectedAreas': affectedAreas,
        'explanation': explanation,
        'calculatedAt': calculatedAt.toIso8601String(),
      };

  Color get color {
    switch (level) {
      case FloodRiskLevel.low: return const Color(0xFF00C853);
      case FloodRiskLevel.moderate: return const Color(0xFFFFD600);
      case FloodRiskLevel.high: return const Color(0xFFFF6D00);
      case FloodRiskLevel.critical: return const Color(0xFFD50000);
    }
  }

  String get levelLabel {
    switch (level) {
      case FloodRiskLevel.low: return 'Low Risk';
      case FloodRiskLevel.moderate: return 'Moderate Risk';
      case FloodRiskLevel.high: return 'High Risk';
      case FloodRiskLevel.critical: return 'Critical Risk';
    }
  }
}
