import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/listing/data/listing_repository.dart';
import 'package:roomie/features/listing/domain/models/listing_draft.dart';
import 'package:roomie/features/listing/presentation/controllers/update_listing_controller.dart';

import '../../fakes/fake_listing_repository.dart';

const _draft = ListingDraft(
  type: 'offering',
  title: 'Título nuevo',
  city: 'Valencia',
  neighborhood: 'Ruzafa',
  price: 450,
);

void main() {
  group('UpdateListingController', () {
    test('sube fotos nuevas y conserva las existentes (en ese orden)', () async {
      final fakeRepo = FakeListingRepository();
      final container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(updateListingControllerProvider.notifier)
          .save(
            'l1',
            _draft,
            newPhotos: [(bytes: Uint8List(0), extension: 'jpg')],
            keptPhotoUrls: const ['https://example.com/vieja.jpg'],
          );

      expect(updated, isTrue);
      expect(fakeRepo.lastUpdatedId, 'l1');
      expect(fakeRepo.lastUpdatedDraft?.title, 'Título nuevo');
      expect(fakeRepo.lastPhotoUrls, [
        'https://example.com/vieja.jpg',
        'https://example.com/photo_0.jpg',
      ]);
    });

    test('deja estado de error y devuelve false si falla', () async {
      final fakeRepo = FakeListingRepository(updateError: Exception('fallo'));
      final container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(updateListingControllerProvider.notifier)
          .save('l1', _draft, newPhotos: const [], keptPhotoUrls: const []);

      expect(updated, isFalse);
      expect(container.read(updateListingControllerProvider).hasError, isTrue);
    });
  });
}
