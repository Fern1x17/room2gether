import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/listing_repository.dart';
import '../../domain/listing_policy.dart';
import '../../domain/models/listing_draft.dart';

class CreateListingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Crea la publicación. Devuelve `true` si se creó; si falla o se incumple
  /// la precondición de CU-06 (ya hay una publicación activa), deja el estado
  /// en error con un mensaje en español y devuelve `false`.
  Future<bool> create(ListingDraft draft, {required List<PendingPhoto> photos}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(listingRepositoryProvider);

      final activeCount = await repository.countMyActiveListings();
      if (!canCreateListing(activeListingsCount: activeCount)) {
        state = AsyncError(
          'Ya tienes una publicación activa. Elimínala antes de crear otra.',
          StackTrace.current,
        );
        return false;
      }

      final photoUrls = photos.isEmpty
          ? <String>[]
          : await repository.uploadPhotos(photos);
      await repository.createListing(draft, photoUrls: photoUrls);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo crear la publicación. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }
}

final createListingControllerProvider =
    AsyncNotifierProvider<CreateListingController, void>(CreateListingController.new);
