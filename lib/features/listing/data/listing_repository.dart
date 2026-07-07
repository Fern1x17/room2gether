import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/listing_draft.dart';

/// Una foto pendiente de subir: bytes + extensión del fichero original.
typedef PendingPhoto = ({Uint8List bytes, String extension});

abstract class ListingRepository {
  Future<int> countMyActiveListings();

  Future<List<String>> uploadPhotos(List<PendingPhoto> photos);

  Future<void> createListing(ListingDraft draft, {required List<String> photoUrls});
}

class SupabaseListingRepository implements ListingRepository {
  SupabaseListingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<int> countMyActiveListings() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('listings')
        .select('id')
        .eq('owner_id', userId)
        .eq('status', 'active');
    return rows.length;
  }

  @override
  Future<List<String>> uploadPhotos(List<PendingPhoto> photos) async {
    final userId = _client.auth.currentUser!.id;
    final urls = <String>[];
    for (final photo in photos) {
      final path =
          '$userId/${DateTime.now().microsecondsSinceEpoch}.${photo.extension}';
      await _client.storage.from('listing-photos').uploadBinary(path, photo.bytes);
      urls.add(_client.storage.from('listing-photos').getPublicUrl(path));
    }
    return urls;
  }

  @override
  Future<void> createListing(
    ListingDraft draft, {
    required List<String> photoUrls,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('listings').insert({
      'owner_id': userId,
      'type': draft.type,
      'title': draft.title,
      'description': draft.description,
      'city': draft.city,
      'neighborhood': draft.neighborhood,
      'price': draft.price,
      'budget_min': draft.budgetMin,
      'budget_max': draft.budgetMax,
      'photos': photoUrls,
    });
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return SupabaseListingRepository(supabase);
});
