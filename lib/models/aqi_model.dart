import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AqiCategory {
  good,        // 0-50    — Green
  moderate,    // 51-100  — Yellow
  sensitive,   // 101-150 — Orange
  unhealthy,   // 151-200 — Red
  veryUnhealthy, // 201-300 — Purple
  hazardous,   // 301-500 — Maroon
}

class AqiReading {
  final int aqi;
  final AqiCategory category;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double co;
  final DateTime timestamp;
  final String city;

  const AqiReading({
    required this.aqi,
    required this.category,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.co,
    required this.timestamp,
    required this.city,
  });

  factory AqiReading.fromJson(Map<String, dynamic> json) {
    final aqiVal = (json['aqi'] as num).toInt();
    final rawCategory = json['category'];
    return AqiReading(
      aqi: aqiVal,
      category: _aqiCategoryFromJson(rawCategory, aqiVal),
      pm25: (json['pm25'] as num?)?.toDouble() ?? 0,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 0,
      o3: (json['o3'] as num?)?.toDouble() ?? 0,
      no2: (json['no2'] as num?)?.toDouble() ?? 0,
      co: (json['co'] as num?)?.toDouble() ?? 0,
      timestamp: _dateTimeFromJson(json['timestamp']) ?? DateTime.now(),
      city: json['city'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'aqi': aqi,
        'category': category.name,
        'pm25': pm25,
        'pm10': pm10,
        'o3': o3,
        'no2': no2,
        'co': co,
        'timestamp': timestamp.toIso8601String(),
        'city': city,
      };

  Color get color {
    switch (category) {
      case AqiCategory.good: return const Color(0xFF00C853);
      case AqiCategory.moderate: return const Color(0xFFFFD600);
      case AqiCategory.sensitive: return const Color(0xFFFF6D00);
      case AqiCategory.unhealthy: return const Color(0xFFD50000);
      case AqiCategory.veryUnhealthy: return const Color(0xFF6A1B9A);
      case AqiCategory.hazardous: return const Color(0xFF4A0000);
    }
  }

  String get categoryLabel {
    switch (category) {
      case AqiCategory.good: return 'Good';
      case AqiCategory.moderate: return 'Moderate';
      case AqiCategory.sensitive: return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy: return 'Unhealthy';
      case AqiCategory.veryUnhealthy: return 'Very Unhealthy';
      case AqiCategory.hazardous: return 'Hazardous';
    }
  }

  String get healthAdvice {
    switch (category) {
      case AqiCategory.good: return 'Air quality is satisfactory. Enjoy outdoor activities.';
      case AqiCategory.moderate: return 'Sensitive individuals should limit prolonged outdoor exertion.';
      case AqiCategory.sensitive: return 'People with respiratory or heart conditions should reduce outdoor activity.';
      case AqiCategory.unhealthy: return 'Everyone should reduce prolonged outdoor exertion. Wear an N95 mask outdoors.';
      case AqiCategory.veryUnhealthy: return 'Avoid outdoor activities. Keep windows closed. Use air purifiers if available.';
      case AqiCategory.hazardous: return 'Health emergency. Stay indoors. Avoid all outdoor activity. Seek medical help if experiencing symptoms.';
    }
  }

  static AqiCategory categoryFromIndex(int aqi) {
    if (aqi <= 50) return AqiCategory.good;
    if (aqi <= 100) return AqiCategory.moderate;
    if (aqi <= 150) return AqiCategory.sensitive;
    if (aqi <= 200) return AqiCategory.unhealthy;
    if (aqi <= 300) return AqiCategory.veryUnhealthy;
    return AqiCategory.hazardous;
  }

  static AqiCategory _aqiCategoryFromJson(dynamic raw, int aqiVal) {
    if (raw is String) {
      for (final c in AqiCategory.values) {
        if (c.name == raw) return c;
      }
    }
    return categoryFromIndex(aqiVal);
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class HourlyAqiPoint {
  final DateTime hour;
  final int aqi;
  const HourlyAqiPoint({required this.hour, required this.aqi});

  factory HourlyAqiPoint.fromJson(Map<String, dynamic> json) {
    return HourlyAqiPoint(
      hour: AqiReading._dateTimeFromJson(json['hour']) ?? DateTime.now(),
      aqi: (json['aqi'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'hour': hour.toIso8601String(),
        'aqi': aqi,
      };
}
