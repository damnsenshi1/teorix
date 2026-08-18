import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Loads versioned course packs from Supabase when available and keeps a local
/// JSON cache. The bundled assets remain the final offline fallback, so an
/// outage never blocks studying.
class RemoteContentService {
  RemoteContentService._();
  static final instance = RemoteContentService._();

  static const _cachePrefix = 'remote_content_pack_v12';

  String _cacheKey(String countryId, String type, String locale) =>
      '${_cachePrefix}_${countryId}_${type}_$locale';

  Future<List<dynamic>?> loadPack({
    required String countryId,
    required String type,
    required String locale,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final rows = await client
            .from('content_packs')
            .select('payload,version')
            .eq('country_id', countryId)
            .eq('content_type', type)
            .eq('locale', locale)
            .eq('is_active', true)
            .order('version', ascending: false)
            .limit(1);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first);
          final payload = row['payload'];
          final list = payload is List
              ? List<dynamic>.from(payload)
              : payload is String
                  ? List<dynamic>.from(jsonDecode(payload) as List)
                  : null;
          if (list != null && list.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              _cacheKey(countryId, type, locale),
              jsonEncode(list),
            );
            return list;
          }
        }
      } catch (_) {
        // Network/backend failure: use the last good cache below.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey(countryId, type, locale));
    if (cached == null || cached.isEmpty) return null;
    try {
      return List<dynamic>.from(jsonDecode(cached) as List);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((e) => e.startsWith(_cachePrefix))) {
      await prefs.remove(key);
    }
  }
}
