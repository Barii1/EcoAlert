import '../models/flood_model.dart';

/// Static hazard zones per city for map visualization.
/// (lat, lon, radiusM, name, type) where type is `aqi` or `flood`.
class CityHazardZones {
  CityHazardZones._();

  static const lahore = [
    (31.5700, 74.2850, 1200.0, 'Ravi River Corridor', 'flood'),
    (31.5880, 74.3110, 900.0, 'Shahdara Township', 'flood'),
    (31.5590, 74.3130, 700.0, 'Data Darbar / Old City', 'flood'),
    (31.5230, 74.2780, 800.0, 'Gulshan Ravi Low Lying', 'flood'),
    (31.5040, 74.3450, 1000.0, 'Youhanabad Drain Area', 'flood'),
    (31.5204, 74.3587, 1500.0, 'City Centre (AQI)', 'aqi'),
    (31.4680, 74.2730, 900.0, 'Sundar Industrial Zone', 'aqi'),
    (31.5450, 74.3200, 1100.0, 'Gulberg III', 'aqi'),
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
  static int zoneAqi(String zoneName, int cityAqi) {
    final spread = zoneName.hashCode.abs() % 90;
    return (cityAqi - 25 + spread).clamp(25, 320);
  }

  /// Per-zone flood risk score 0–100.
  static double zoneFloodScore(String zoneName, FloodRiskLevel level) {
    final base = switch (level) {
      FloodRiskLevel.low => 22.0,
      FloodRiskLevel.moderate => 48.0,
      FloodRiskLevel.high => 72.0,
      FloodRiskLevel.critical => 92.0,
    };
    final jitter = (zoneName.hashCode.abs() % 18) - 9;
    return (base + jitter).clamp(8, 98);
  }
}
