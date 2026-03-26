import 'package:flutter/material.dart';
import '../models/aqi_model.dart';

/// Computes an adaptive danger accent color based on current environmental conditions.
/// The UI subtly shifts from green → yellow → orange → red as danger increases.
/// This gives the app a living, reactive feel during FYP demos.
class DangerThemeProvider extends ChangeNotifier {
  int _dangerLevel = 0; // 0-5 scale

  int get dangerLevel => _dangerLevel;

  /// Primary accent color that shifts based on danger.
  Color get accentColor {
    switch (_dangerLevel) {
      case 0: return const Color(0xFF00C853); // Green — all clear
      case 1: return const Color(0xFF06C8FF); // Cyan — default/normal
      case 2: return const Color(0xFFFFD600); // Yellow — moderate
      case 3: return const Color(0xFFFF9100); // Orange — unhealthy
      case 4: return const Color(0xFFFF1744); // Red — dangerous
      case 5: return const Color(0xFFD50000); // Deep red — hazardous
      default: return const Color(0xFF06C8FF);
    }
  }

  /// Glow color for shadows/borders.
  Color get glowColor => accentColor.withOpacity(0.3);

  /// Gradient for FAB and highlights.
  List<Color> get accentGradient => [
        accentColor,
        accentColor.withOpacity(0.7),
      ];

  /// Status text for the current danger level.
  String get statusText {
    switch (_dangerLevel) {
      case 0: return 'All Clear';
      case 1: return 'Normal';
      case 2: return 'Moderate Risk';
      case 3: return 'Elevated Risk';
      case 4: return 'High Danger';
      case 5: return 'EMERGENCY';
      default: return 'Normal';
    }
  }

  /// Update from AQI reading.
  void updateFromAqi(AqiReading? reading) {
    if (reading == null) {
      _setLevel(1);
      return;
    }
    switch (reading.category) {
      case AqiCategory.good:
        _setLevel(0);
        break;
      case AqiCategory.moderate:
        _setLevel(2);
        break;
      case AqiCategory.sensitive:
        _setLevel(3);
        break;
      case AqiCategory.unhealthy:
        _setLevel(3);
        break;
      case AqiCategory.veryUnhealthy:
        _setLevel(4);
        break;
      case AqiCategory.hazardous:
        _setLevel(5);
        break;
    }
  }

  /// Update from alert count and max severity.
  void updateFromAlerts(int highSeverityCount) {
    if (highSeverityCount >= 3) {
      _setLevel(5);
    } else if (highSeverityCount >= 1) {
      // Only escalate, never reduce from AQI-driven level.
      if (_dangerLevel < 4) _setLevel(4);
    }
  }

  void _setLevel(int level) {
    if (_dangerLevel != level) {
      _dangerLevel = level;
      notifyListeners();
    }
  }
}
