import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listing_repository.dart';
import '../../domain/models/listing_draft.dart';

class UpdateListingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Guarda los cambios de una publicación (CU-08): sube las fotos nuevas,
  /// conserva las existentes que no se quitaron y actualiza la fila.
  /// (No se llama `update` porque AsyncNotifier ya define ese método.)
  Future<bool> save(
    String id,
    ListingDraft draft, {
    required List<PendingPhoto> newPhotos,
    required List<String> keptPhotoUrls,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(listingRepositoryProvider);
      final uploaded = newPhotos.isEmpty
          ? <String>[]
          : await repository.uploadPhotos(newPhotos);
      await repository.updateListing(
        id,
        draft,
        photoUrls: [...keptPhotoUrls, ...uploaded],
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo guardar la publicación. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }
}

final updateListingControllerProvider =
    AsyncNotifierProvider<UpdateListingController, void>(
      UpdateListingController.new,
    );
