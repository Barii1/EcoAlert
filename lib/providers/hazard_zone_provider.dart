import 'package:flutter/foundation.dart';

import '../config/city_hazard_zones.dart';
import '../config/supabase_tables.dart';
import '../models/hazard_zone_model.dart';
import '../services/supabase_service.dart';

class HazardZoneProvider extends ChangeNotifier {
  HazardZoneProvider({SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService? _supabaseService;
  List<HazardZoneModel> _zones = [];
  bool _isLoading = false;

  List<HazardZoneModel> get zones => List.unmodifiable(_zones);
  bool get isLoading => _isLoading;

  List<HazardZoneModel> get allZones {
    if (_zones.isNotEmpty) return List.unmodifiable(_zones);
    // Fall back to static config zones when DB is unavailable
    return [..._fallbackZones('aqi'), ..._fallbackZones('flood')];
  }

  Future<void> init() async {
    if (_supabaseService == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _supabaseService!.getTable(
        SupabaseTables.hazardZones,
        orderBy: 'created_at',
        descending: true,
        limit: 200,
      );
      _zones = rows.map(HazardZoneModel.fromJson).toList();
      debugPrint('[HazardZoneProvider] Loaded ${_zones.length} zones from DB');
    } catch (e) {
      // Table may not exist yet — fallback zones keep the map working
      debugPrint('[HazardZoneProvider] fetch failed, using fallback: $e');
      _zones = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
