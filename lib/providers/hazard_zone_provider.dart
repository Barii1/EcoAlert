import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/city_hazard_zones.dart';
import '../config/supabase_tables.dart';
import '../models/hazard_zone_model.dart';
import '../services/supabase_service.dart';

class HazardZoneProvider extends ChangeNotifier {
  HazardZoneProvider({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService? _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  List<HazardZoneModel> _zones = [];
  bool _isLoading = false;

  List<HazardZoneModel> get zones => List.unmodifiable(_zones);
  bool get isLoading => _isLoading;

  List<HazardZoneModel> get allZones {
    if (_zones.isNotEmpty) return List.unmodifiable(_zones);
    final aqi = _fallbackZones('aqi');
    final flood = _fallbackZones('flood');
    return [...aqi, ...flood];
  }

  void init() {
    if (_supabaseService == null) return;
    _subscription?.cancel();
    _isLoading = true;

    _subscription = _supabaseService!
        .streamTable(
          SupabaseTables.hazardZones,
          primaryKeys: ['id'],
        )
        .listen(
          (rows) {
            _zones = rows.map(HazardZoneModel.fromJson).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            debugPrint('[HazardZoneProvider] stream error: $e');
            notifyListeners();
          },
        );
  }

  List<HazardZoneModel> zonesForType(String type) {
    final filtered = _zones.where((z) => z.type == type).toList();
    if (filtered.isNotEmpty) return filtered;
    return _fallbackZones(type);
  }

  List<HazardZoneModel> _fallbackZones(String type) {
    final tuples = CityHazardZones.filteredAll(aqiOnly: type == 'aqi');
    return tuples
        .map(
          (z) => HazardZoneModel(
            id: '${z.$4}-${z.$5}',
            name: z.$4,
            city: 'Unknown',
            type: z.$5,
            latitude: z.$1,
            longitude: z.$2,
            radiusMeters: z.$3,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
