import 'package:flutter/material.dart';

enum FloodRiskLevel { low, moderate, high, critical }

DateTime? _floodDateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, double> _floodDoubleMapFromJson(dynamic value) {
  final source = value is Map<String, dynamic> ? value : <String, dynamic>{};
  return source.map((key, raw) {
    final number = raw is num ? raw.toDouble() : double.tryParse('$raw');
    return MapEntry(key, number ?? 0.0);
  });
}

class RainfallData {
  final double mm24h; // Rainfall in last 24 hours (mm)
  final double mmPerHour; // Current intensity (mm/hr)
  final double mm48h; // Rainfall in last 48 hours (mm)
  final double temperature; // Ambient temperature (°C) — used by ML model
  final double humidity; // Relative humidity (%) — used by ML model
  final DateTime timestamp;

  const RainfallData({
    required this.mm24h,
    required this.mmPerHour,
    required this.mm48h,
    this.temperature = 0.0,
    this.humidity = 0.0,
    required this.timestamp,
  });

  factory RainfallData.fromJson(Map<String, dynamic> json) {
    return RainfallData(
      mm24h: (json['mm24h'] as num).toDouble(),
      mmPerHour: (json['mmPerHour'] as num).toDouble(),
      mm48h: (json['mm48h'] as num).toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: _floodDateTimeFromJson(json['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mm24h': mm24h,
        'mmPerHour': mmPerHour,
        'mm48h': mm48h,
        'temperature': temperature,
        'humidity': humidity,
        'timestamp': timestamp.toIso8601String(),
      };
}

class FloodRisk {
  final int riskScore; // 0-100
  final FloodRiskLevel level;
  final RainfallData rainfall;
  final String city;
  final List<String> affectedAreas;
  final String explanation;
  final DateTime calculatedAt;
  final double? cloudburstProbability; // 0-1 from backend ML model
  final FloodRiskLevel? cloudburstLevel;
  final bool cloudburstUsingModel;
  final Map<String, double> cloudburstFeatures;

  const FloodRisk({
    required this.riskScore,
    required this.level,
    required this.rainfall,
    required this.city,
    required this.affectedAreas,
    required this.explanation,
    required this.calculatedAt,
    this.cloudburstProbability,
    this.cloudburstLevel,
    this.cloudburstUsingModel = false,
    this.cloudburstFeatures = const {},
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
      cloudburstProbability:
          (json['cloudburstProbability'] as num?)?.toDouble(),
      cloudburstLevel: json['cloudburstLevel'] == null
          ? null
          : FloodRiskLevel.values.firstWhere(
              (l) => l.name == json['cloudburstLevel'],
              orElse: () => FloodRiskLevel.low,
            ),
      cloudburstUsingModel: json['cloudburstUsingModel'] as bool? ?? false,
      cloudburstFeatures: _floodDoubleMapFromJson(json['cloudburstFeatures']),
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
        'cloudburstProbability': cloudburstProbability,
        'cloudburstLevel': cloudburstLevel?.name,
        'cloudburstUsingModel': cloudburstUsingModel,
        'cloudburstFeatures': cloudburstFeatures,
      };

  Color get color {
    switch (level) {
      case FloodRiskLevel.low:
        return const Color(0xFF00C853);
      case FloodRiskLevel.moderate:
        return const Color(0xFFFFD600);
      case FloodRiskLevel.high:
        return const Color(0xFFFF6D00);
      case FloodRiskLevel.critical:
        return const Color(0xFFD50000);
    }
  }

  String get levelLabel {
    switch (level) {
      case FloodRiskLevel.low:
        return 'Low Risk';
      case FloodRiskLevel.moderate:
        return 'Moderate Risk';
      case FloodRiskLevel.high:
        return 'High Risk';
      case FloodRiskLevel.critical:
        return 'Critical Risk';
    }
  }
}
