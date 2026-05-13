import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent local cache using SharedPreferences.
///
/// Every data provider should:
///   1. Call [save] after a successful API/remote fetch.
///   2. Call [load] when offline (or on cold start) to serve last-known data.
///   3. Call [isFresh] to decide whether cached data is still usable.
///
/// Data is stored as JSON strings with a timestamp so the UI can show
/// "Last updated X minutes ago" when in offline mode.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  // ── TTL (Time-To-Live) per data type ─────────────────────────────────────
  static const Duration aqiTtl     = Duration(hours: 1);
  static const Duration floodTtl   = Duration(hours: 2);
  static const Duration weatherTtl = Duration(hours: 1);
  static const Duration alertsTtl  = Duration(minutes: 30);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _aqiPrefix     = 'cache_aqi_';
  static const String _floodPrefix   = 'cache_flood_';
  static const String _weatherPrefix = 'cache_weather_';
  static const String _alertsKey     = 'cache_alerts';

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveAqi(String city, Map<String, dynamic> data) =>
      _save('$_aqiPrefix${city.toLowerCase()}', data);

  Future<void> saveFlood(String city, Map<String, dynamic> data) =>
      _save('$_floodPrefix${city.toLowerCase()}', data);

  Future<void> saveWeather(String city, Map<String, dynamic> data) =>
      _save('$_weatherPrefix${city.toLowerCase()}', data);

  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = {
      'data': alerts,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_alertsKey, jsonEncode(envelope));
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loadAqi(String city) =>
      _load('$_aqiPrefix${city.toLowerCase()}');

  Future<Map<String, dynamic>?> loadFlood(String city) =>
      _load('$_floodPrefix${city.toLowerCase()}');

  Future<Map<String, dynamic>?> loadWeather(String city) =>
      _load('$_weatherPrefix${city.toLowerCase()}');

  Future<List<Map<String, dynamic>>?> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsKey);
    if (raw == null) return null;
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final list = envelope['data'] as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Freshness check ───────────────────────────────────────────────────────

  Future<bool> isAqiFresh(String city) =>
      _isFresh('$_aqiPrefix${city.toLowerCase()}', aqiTtl);

  Future<bool> isFloodFresh(String city) =>
      _isFresh('$_floodPrefix${city.toLowerCase()}', floodTtl);

  Future<bool> isWeatherFresh(String city) =>
      _isFresh('$_weatherPrefix${city.toLowerCase()}', weatherTtl);

  /// Returns a human-readable string like "23 minutes ago" or null if no cache.
  Future<String?> cacheAge(String key) async {
    final data = await _load(key);
    if (data == null) return null;
    final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
    if (cachedAt == null) return null;
    final diff = DateTime.now().difference(cachedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }

  Future<String?> aqiCacheAge(String city) =>
      cacheAge('$_aqiPrefix${city.toLowerCase()}');

  Future<String?> floodCacheAge(String city) =>
      cacheAge('$_floodPrefix${city.toLowerCase()}');

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) =>
        k.startsWith(_aqiPrefix) ||
        k.startsWith(_floodPrefix) ||
        k.startsWith(_weatherPrefix) ||
        k == _alertsKey);
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('[CacheService] All caches cleared');
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _save(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final envelope = {
        ...data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, jsonEncode(envelope));
      debugPrint('[CacheService] Saved: $key');
    } catch (e) {
      debugPrint('[CacheService] Save failed for $key: $e');
    }
  }

  Future<Map<String, dynamic>?> _load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CacheService] Load failed for $key: $e');
      return null;
    }
  }

  Future<bool> _isFresh(String key, Duration ttl) async {
    final data = await _load(key);
    if (data == null) return false;
    final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < ttl;
  }
}
