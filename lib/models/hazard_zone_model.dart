class HazardZoneModel {
  HazardZoneModel({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String name;
  final String city;
  final String type; // 'aqi' or 'flood'
  final double latitude;
  final double longitude;
  final double radiusMeters;

  factory HazardZoneModel.fromJson(Map<String, dynamic> json) {
    return HazardZoneModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Zone',
      city: json['city'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'aqi',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0,
      radiusMeters: (json['radius_m'] as num?)?.toDouble() ?? 800,
    );
  }

  // Supabase rows use the same column names as fromJson (lat, lon, radius_m).
  factory HazardZoneModel.fromSupabase(Map<String, dynamic> row) =>
      HazardZoneModel.fromJson(row);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'type': type,
      'lat': latitude,
      'lon': longitude,
      'radius_m': radiusMeters,
    };
  }
}
