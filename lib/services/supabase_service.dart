import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final response =
        await _client.from(table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getTable(
    String table, {
    String? orderBy,
    bool descending = false,
    int? limit,
    String? whereField,
    dynamic whereValue,
  }) async {
    var query = _client.from(table).select();
    final filtered = whereField != null
        ? query.eq(whereField, whereValue)
        : query;
    final ordered = orderBy != null
        ? filtered.order(orderBy, ascending: !descending)
        : filtered;
    final limited = limit != null ? ordered.limit(limit) : ordered;
    final data = await limited;
    return (data as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> streamTable(
    String table, {
    required List<String> primaryKeys,
    String? orderBy,
    bool descending = false,
    int? limit,
    String? whereField,
    dynamic whereValue,
  }) {
    // Build the chain. Each call returns a compatible stream type.
    final base = _client.from(table).stream(primaryKey: primaryKeys);

    dynamic builder = whereField != null ? base.eq(whereField, whereValue) : base;
    if (orderBy != null) builder = builder.order(orderBy, ascending: !descending);
    if (limit != null) builder = builder.limit(limit);

    return (builder as Stream<List<Map<String, dynamic>>>).map(
      (rows) => rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  Future<String> insertRow(String table, Map<String, dynamic> data) async {
    final response =
        await _client.from(table).insert(data).select('id').single();
    return response['id'] as String;
  }

  Future<void> updateRow(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _client.from(table).update(data).eq('id', id);
  }
}
