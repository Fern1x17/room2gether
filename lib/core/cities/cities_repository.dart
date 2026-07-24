import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import '../utils/normalize_text.dart';
import 'city.dart';

abstract class CitiesRepository {
  /// Devuelve la fila de `cities` para la localidad de Google Places
  /// [placeId], creándola si no existe (RPC `get_or_create_city`).
  Future<City> getOrCreateCity({required String placeId, required String name});
}

class SupabaseCitiesRepository implements CitiesRepository {
  SupabaseCitiesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<City> getOrCreateCity({
    required String placeId,
    required String name,
  }) async {
    final row = await _client
        .rpc(
          'get_or_create_city',
          params: {
            'p_place_id': placeId,
            'p_name': name,
            'p_normalized_name': normalizeText(name),
          },
        )
        .single();
    return City.fromMap(row);
  }
}

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  return SupabaseCitiesRepository(supabase);
});
