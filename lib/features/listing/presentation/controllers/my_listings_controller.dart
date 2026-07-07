import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/domain/models/listing.dart';
import '../../data/listing_repository.dart';

/// Publicaciones del usuario autenticado ("entra en el perfil y selecciona
/// una publicación", CU-07/CU-08).
final myListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.read(listingRepositoryProvider).fetchMyListings();
});

class DeleteListingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Devuelve `true` si la publicación quedó eliminada.
  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await ref.read(listingRepositoryProvider).deleteListing(id);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo eliminar la publicación. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }
}

final deleteListingControllerProvider =
    AsyncNotifierProvider<DeleteListingController, void>(DeleteListingController.new);
