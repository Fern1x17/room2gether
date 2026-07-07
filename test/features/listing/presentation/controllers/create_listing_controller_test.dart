import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/listing/data/listing_repository.dart';
import 'package:roomie/features/listing/domain/models/listing_draft.dart';
import 'package:roomie/features/listing/presentation/controllers/create_listing_controller.dart';

import '../../fakes/fake_listing_repository.dart';

const _draft = ListingDraft(
  type: 'offering',
  title: 'Habitación centro',
  city: 'Valencia',
  neighborhood: 'Ruzafa',
  price: 400,
);

void main() {
  group('CreateListingController', () {
    test('crea la publicación subiendo las fotos primero', () async {
      final fakeRepo = FakeListingRepository();
      final container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final created = await container
          .read(createListingControllerProvider.notifier)
          .create(_draft, photos: [(bytes: Uint8List(0), extension: 'jpg')]);

      expect(created, isTrue);
      expect(fakeRepo.uploadedPhotoCount, 1);
      expect(fakeRepo.lastCreatedDraft?.title, 'Habitación centro');
      expect(fakeRepo.lastPhotoUrls, hasLength(1));
    });

    test('bloquea si ya existe una publicación activa (precondición CU-06)', () async {
      final fakeRepo = FakeListingRepository(activeListings: 1);
      final container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final created = await container
          .read(createListingControllerProvider.notifier)
          .create(_draft, photos: const []);

      expect(created, isFalse);
      expect(fakeRepo.lastCreatedDraft, isNull);
      final state = container.read(createListingControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error,
        'Ya tienes una publicación activa. Elimínala antes de crear otra.',
      );
    });

    test('deja estado de error si la inserción falla', () async {
      final fakeRepo = FakeListingRepository(createError: Exception('fallo'));
      final container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final created = await container
          .read(createListingControllerProvider.notifier)
          .create(_draft, photos: const []);

      expect(created, isFalse);
      expect(container.read(createListingControllerProvider).hasError, isTrue);
    });
  });
}
