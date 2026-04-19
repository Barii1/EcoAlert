import '../models/flood_model.dart';

/// Rule-based flood risk scoring.
/// Score = weighted combination of rainfall intensity, 24h total, and city base risk.
/// Replace with ML model call in Phase 2.
class FloodRiskCalculator {
  /// City base risk factors (0-30 points) based on historical flood frequency in Pakistan
  static const Map<String, int> _cityBaseRisk = {
    'Lahore': 20,
    'Karachi': 25,
    'Peshawar': 28,
    'Multan': 18,
    'Faisalabad': 15,
    'Islamabad': 12,
    'Hyderabad': 22,
    'Sukkur': 30,
  };

  FloodRisk calculate(RainfallData rainfall, String city) {
    int score = 0;

    // Base risk from city location (0-30)
    score += _cityBaseRisk[city] ?? 15;

    // 24h rainfall contribution (0-35)
    if (rainfall.mm24h > 100) {
      score += 35;
    } else if (rainfall.mm24h > 50) {
      score += 25;
    } else if (rainfall.mm24h > 25) {
      score += 15;
    } else if (rainfall.mm24h > 10) {
      score += 8;
    }

    // Intensity contribution (0-25)
    if (rainfall.mmPerHour > 30) {
      score += 25;
    } else if (rainfall.mmPerHour > 20) {
      score += 18;
    } else if (rainfall.mmPerHour > 10) {
      score += 10;
    } else if (rainfall.mmPerHour > 5) {
      score += 5;
    }

    // 48h accumulation (soil saturation proxy) (0-10)
    if (rainfall.mm48h > 150) {
      score += 10;
    } else if (rainfall.mm48h > 75) {
      score += 6;
    } else if (rainfall.mm48h > 30) {
      score += 3;
    }

    score = score.clamp(0, 100);

    FloodRiskLevel level;
    if (score <= 25) {
      level = FloodRiskLevel.low;
    } else if (score <= 50) {
      level = FloodRiskLevel.moderate;
    } else if (score <= 75) {
      level = FloodRiskLevel.high;
    } else {
      level = FloodRiskLevel.critical;
    }

    return FloodRisk(
      riskScore: score,
      level: level,
      rainfall: rainfall,
      city: city,
      affectedAreas: _getAffectedAreas(city, level),
      explanation: _buildExplanation(rainfall, score),
      calculatedAt: DateTime.now(),
    );
  }

  String _buildExplanation(RainfallData r, int score) {
    final parts = <String>[];
    if (r.mm24h > 25) {
      parts.add('${r.mm24h.toStringAsFixed(0)}mm in past 24h');
    }
    if (r.mmPerHour > 10) {
      parts.add('${r.mmPerHour.toStringAsFixed(0)}mm/hr intensity');
    }
    if (r.mm48h > 75) {
      parts.add('saturated soil from 48h accumulation');
    }
    return parts.isEmpty ? 'Based on current conditions and location risk.' : 'Contributing factors: ${parts.join(', ')}.';
  }

  List<String> _getAffectedAreas(String city, FloodRiskLevel level) {
    if (level == FloodRiskLevel.low) {
      return [];
    }
    final Map<String, List<String>> areas = {
      'Lahore': ['Ravi River banks', 'Shahdara', 'Data Darbar area'],
      'Karachi': ['Lyari River corridor', 'Orangi Town', 'Korangi'],
      'Peshawar': ['Kabul River banks', 'Charsadda Road areas'],
    };
    return areas[city] ?? ['Low-lying areas', 'River-adjacent zones'];
  }
}
