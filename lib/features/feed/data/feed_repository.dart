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

  @override
  Future<List<Listing>> fetchListings(ListingFilter filter) async {
    var query = _client.from('listings').select().eq('status', 'active');

    if (filter.city != null) {
      query = query.eq('city', filter.city!);
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
    final row = await _client.from('listings').select().eq('id', id).single();
    return Listing.fromMap(row);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return SupabaseFeedRepository(supabase);
});
