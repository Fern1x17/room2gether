import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/listing_filter.dart';

/// Búsquedas recientes guardadas SOLO en el dispositivo (CU-09): son un dato
/// personal efímero que no necesita estar en el servidor.
abstract class RecentSearchesRepository {
  Future<List<ListingFilter>> load();

  Future<void> save(ListingFilter filter);
}

class SharedPreferencesRecentSearchesRepository implements RecentSearchesRepository {
  static const _key = 'recent_searches';
  static const _maxEntries = 10;

  @override
  Future<List<ListingFilter>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) => ListingFilter.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(ListingFilter filter) async {
    if (filter.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((existing) => existing == filter);
    current.insert(0, filter);
    final capped = current.take(_maxEntries).toList();
    await prefs.setStringList(
      _key,
      capped.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>((ref) {
  return SharedPreferencesRecentSearchesRepository();
});
