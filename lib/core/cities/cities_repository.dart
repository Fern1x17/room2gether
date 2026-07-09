import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import 'city.dart';

abstract class CitiesRepository {
  Future<List<City>> fetchActiveCities();
}

class SupabaseCitiesRepository implements CitiesRepository {
  SupabaseCitiesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<City>> fetchActiveCities() async {
    final rows = await _client
        .from('cities')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    return rows.map(City.fromMap).toList();
  }
}

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  return SupabaseCitiesRepository(supabase);
});

/// Ciudades activas, cargadas una sola vez; el filtrado del selector es en
/// memoria. (El catálogo solo cambia por migración/panel, no hace falta
/// recargarlo por usuario ni por sesión.)
final activeCitiesProvider = FutureProvider<List<City>>((ref) {
  return ref.read(citiesRepositoryProvider).fetchActiveCities();
});
