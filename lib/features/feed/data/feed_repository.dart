import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/listing.dart';
import '../domain/models/listing_filter.dart';

abstract class FeedRepository {
  Future<List<Listing>> fetchListings(ListingFilter filter);

  Future<Listing> fetchListingById(String id);
}

class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository(this._client);

  final SupabaseClient _client;

  /// Columnas del join de dirección exacta. RLS solo devuelve la fila si es
  /// pública o si la publicación es del usuario actual.
  static const _addressJoin =
      'address:listing_addresses(google_place_id, formatted_address, '
      'latitude, longitude, is_public)';

  /// Nombre público del autor. La RLS de `profiles` permite lectura a
  /// cualquier usuario autenticado, así que el join no necesita política nueva.
  static const _ownerJoin = 'owner:profiles(display_name)';

  @override
  Future<List<Listing>> fetchListings(ListingFilter filter) async {
    var query = _client
        .from('listings')
        .select('*, city:cities(name), $_ownerJoin, $_addressJoin')
        .eq('status', 'active');

    if (filter.cityId != null) {
      query = query.eq('city_id', filter.cityId!);
    }
    if (filter.neighborhood != null) {
      query = query.eq('neighborhood', filter.neighborhood!);
    }
    if (filter.maxPrice != null) {
      // El filtro de precio aplica a ambos tipos: precio mensual (offering)
      // o presupuesto máximo (seeking).
      query = query.or(
        'price.lte.${filter.maxPrice},budget_max.lte.${filter.maxPrice}',
      );
    }
    if (filter.type != null) {
      query = query.eq('type', filter.type!);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map(Listing.fromMap).toList();
  }

  @override
  Future<Listing> fetchListingById(String id) async {
    final row = await _client
        .from('listings')
        .select('*, city:cities(name), $_ownerJoin, $_addressJoin')
        .eq('id', id)
        .single();
    return Listing.fromMap(row);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return SupabaseFeedRepository(supabase);
});
