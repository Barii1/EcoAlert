import 'dart:math' as math;

import '../models/flood_model.dart';

/// Static hazard zones per city for map visualization.
/// (lat, lon, radiusM, name, type) where type is `aqi` or `flood`.
class CityHazardZones {
  CityHazardZones._();

  static const lahore = [
    (31.5700, 74.2850, 950.0, 'Ravi River Corridor', 'flood'),
    (31.5880, 74.3110, 850.0, 'Shahdara Township', 'flood'),
    (31.5590, 74.3130, 650.0, 'Data Darbar / Old City', 'flood'),
    (31.5230, 74.2780, 700.0, 'Gulshan Ravi Low Lying', 'flood'),
    (31.5040, 74.3450, 800.0, 'Youhanabad Drain Area', 'flood'),
    (31.6100, 74.3030, 850.0, 'Ravi Bridge North Bank', 'flood'),
    (31.5760, 74.2920, 750.0, 'Shahdara Drain Belt', 'flood'),
    (31.5410, 74.2660, 650.0, 'Babu Sabu Interchange', 'flood'),
    (31.5670, 74.3220, 600.0, 'Lakshmi Chowk Low Point', 'flood'),
    (31.5110, 74.3330, 600.0, 'Kalma Chowk Underpass', 'flood'),
    (31.5020, 74.3180, 650.0, 'Garden Town Drain', 'flood'),
    (31.4710, 74.2420, 700.0, 'Thokar Niaz Baig Drain', 'flood'),
    (31.4740, 74.3010, 650.0, 'Johar Town Low Point', 'flood'),
    (31.5520, 74.3440, 600.0, 'Lahore Canal Low Bank', 'flood'),
    (31.4490, 74.2930, 700.0, 'Township Drainage Line', 'flood'),
    (31.4210, 74.1930, 850.0, 'Sundar Drain Belt', 'flood'),
    (31.5204, 74.3587, 650.0, 'Mall Road Station', 'aqi'),
    (31.5450, 74.3200, 650.0, 'Gulberg III', 'aqi'),
    (31.4680, 74.2730, 760.0, 'Sundar Industrial Zone', 'aqi'),
    (31.4920, 74.3420, 650.0, 'Model Town', 'aqi'),
    (31.5600, 74.3500, 600.0, 'Garhi Shahu', 'aqi'),
    (31.5790, 74.3560, 650.0, 'Shalimar Gardens', 'aqi'),
    (31.5880, 74.3110, 700.0, 'Shahdara', 'aqi'),
    (31.5010, 74.3220, 650.0, 'Ferozepur Road', 'aqi'),
    (31.4660, 74.4110, 650.0, 'Bahria Town Lahore', 'aqi'),
    (31.3980, 74.2530, 800.0, 'Raiwind Road', 'aqi'),
    (31.4630, 74.2850, 650.0, 'Township', 'aqi'),
    (31.5310, 74.3820, 650.0, 'DHA Phase 5', 'aqi'),
    (31.4750, 74.3780, 650.0, 'Johar Town', 'aqi'),
    (31.4250, 74.1840, 820.0, 'Kasur Road Industrial Belt', 'aqi'),
    (31.5890, 74.2500, 700.0, 'Ravi Road', 'aqi'),
    (31.5520, 74.3700, 600.0, 'Cantt', 'aqi'),
    (31.5170, 74.2850, 650.0, 'Samanabad', 'aqi'),
    (31.5120, 74.2500, 700.0, 'Multan Road', 'aqi'),
    (31.5650, 74.4050, 650.0, 'Airport Corridor', 'aqi'),
    (31.4500, 74.3080, 650.0, 'Peco Road', 'aqi'),
    (31.6100, 74.3350, 760.0, 'Badami Bagh', 'aqi'),
    (31.5370, 74.3040, 620.0, 'Ichhra', 'aqi'),
    (31.5820, 74.3900, 620.0, 'Harbanspura', 'aqi'),
    (31.4930, 74.4100, 650.0, 'Bedian Road', 'aqi'),
  ];

  static const karachi = [
    (24.8700, 67.0200, 1100.0, 'Lyari River Corridor', 'flood'),
    (24.9300, 66.9900, 1000.0, 'Orangi Town', 'flood'),
    (24.8500, 67.0400, 950.0, 'SITE Industrial', 'flood'),
    (24.8300, 67.1000, 800.0, 'Korangi Industrial', 'aqi'),
    (24.8607, 67.0011, 1400.0, 'Karachi City AQI Zone', 'aqi'),
    (24.9050, 67.0750, 1000.0, 'Gulshan-e-Iqbal', 'aqi'),
  ];

  static const islamabad = [
    (33.6800, 73.0500, 900.0, 'Soan River Area', 'flood'),
    (33.7200, 73.0300, 700.0, 'Margalla Foothills', 'flood'),
    (33.7294, 73.0931, 1200.0, 'Islamabad AQI Centre', 'aqi'),
    (33.7000, 73.0700, 850.0, 'Blue Area', 'aqi'),
  ];

  static const peshawar = [
    (34.0200, 71.5100, 1100.0, 'Kabul River Banks', 'flood'),
    (34.0100, 71.5600, 800.0, 'Charsadda Road Area', 'flood'),
    (34.0151, 71.5249, 1300.0, 'Peshawar AQI Zone', 'aqi'),
    (34.0050, 71.5450, 900.0, 'University Town', 'aqi'),
  ];

  static const all = [
    ...lahore,
    ...karachi,
    ...islamabad,
    ...peshawar,
  ];

  static List<(double, double, double, String, String)> forCity(String city) {
    switch (city.toLowerCase()) {
      case 'karachi':
        return karachi;
      case 'islamabad':
        return islamabad;
      case 'peshawar':
        return peshawar;
      default:
        return lahore;
    }
  }

  static List<(double, double, double, String, String)> filtered(
    String city, {
    required bool aqiOnly,
  }) {
    final type = aqiOnly ? 'aqi' : 'flood';
    return forCity(city).where((z) => z.$5 == type).toList();
  }

  static List<(double, double, double, String, String)> filteredAll({
    required bool aqiOnly,
  }) {
    final type = aqiOnly ? 'aqi' : 'flood';
    return all.where((z) => z.$5 == type).toList();
  }

  /// Per-zone AQI spread around city reading so zones look distinct on map.
  static int zoneAqi(String zoneName, int cityAqi, {DateTime? now}) {
    final lower = zoneName.toLowerCase();
    final hash = _stableHash(zoneName);
    final baseOffset = (hash % 43) - 18;
    final hourlyWave = _hourlyWave(zoneName, now ?? DateTime.now()) * 11;
    final zoneBias = switch (lower) {
      final n when n.contains('industrial') => 32,
      final n when n.contains('badami') => 28,
      final n when n.contains('road') => 22,
      final n when n.contains('ravi') => 18,
      final n when n.contains('multan') => 18,
      final n when n.contains('ferozepur') => 18,
      final n when n.contains('airport') => 10,
      final n when n.contains('dha') => -14,
      final n when n.contains('bahria') => -16,
      final n when n.contains('cantt') => -10,
      final n when n.contains('garden') => -8,
      _ => 0,
    };

    return (cityAqi + baseOffset + hourlyWave + zoneBias)
        .round()
        .clamp(25, 320);
  }

  /// Per-zone flood risk score 0–100.
  static double zoneFloodScore(
    String zoneName,
    FloodRiskLevel level, {
    RainfallData? rainfall,
    DateTime? now,
  }) {
    final base = switch (level) {
      FloodRiskLevel.low => 12.0,
      FloodRiskLevel.moderate => 48.0,
      FloodRiskLevel.high => 72.0,
      FloodRiskLevel.critical => 92.0,
    };
    final lower = zoneName.toLowerCase();
    final hash = _stableHash(zoneName);
    final jitter = (hash % 15) - 7;
    final rainfallBoost = rainfall == null
        ? 0.0
        : (rainfall.mm24h * 0.45 +
                rainfall.mm48h * 0.12 +
                rainfall.mmPerHour * 5.0)
            .clamp(0.0, 32.0);
    final zoneBias = switch (lower) {
      final n when n.contains('ravi') => 18.0,
      final n when n.contains('drain') => 16.0,
      final n when n.contains('underpass') => 15.0,
      final n when n.contains('low') => 14.0,
      final n when n.contains('canal') => 11.0,
      final n when n.contains('bridge') => 10.0,
      _ => 0.0,
    };
    final hourlyWave = _hourlyWave(zoneName, now ?? DateTime.now()) * 4;

    return (base + jitter + rainfallBoost + zoneBias + hourlyWave).clamp(4, 98);
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static double _hourlyWave(String value, DateTime now) {
    final seed = _stableHash(value) % 24;
    final hour = now.hour + now.minute / 60.0;
    return math.sin(((hour + seed) / 24.0) * math.pi * 2);
  }
}
