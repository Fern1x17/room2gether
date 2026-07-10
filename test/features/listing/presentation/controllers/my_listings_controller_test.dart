import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/listing/data/listing_repository.dart';
import 'package:room2gether/features/listing/presentation/controllers/my_listings_controller.dart';

import '../../../feed/fakes/fake_feed_repository.dart';
import '../../fakes/fake_listing_repository.dart';

void main() {
  group('myListingsProvider', () {
    test('devuelve las publicaciones propias', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          listingRepositoryProvider.overrideWithValue(
            FakeListingRepository(
              myListings: [fakeListing(title: 'Mi anuncio')],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final listings = await container.read(myListingsProvider.future);

      expect(listings, hasLength(1));
      expect(listings.first.title, 'Mi anuncio');
    });
  });

  group('DeleteListingController', () {
    test('elimina la publicación y devuelve true', () async {
      final fakeRepo = FakeListingRepository(
        myListings: [fakeListing(id: 'l1')],
      );
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          listingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final deleted = await container
          .read(deleteListingControllerProvider.notifier)
          .delete('l1');

      expect(deleted, isTrue);
      expect(fakeRepo.deletedIds, ['l1']);
      expect(fakeRepo.myListings, isEmpty);
    });

    test('deja estado de error y devuelve false si falla', () async {
      final fakeRepo = FakeListingRepository(deleteError: Exception('fallo'));
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          listingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final deleted = await container
          .read(deleteListingControllerProvider.notifier)
          .delete('l1');

      expect(deleted, isFalse);
      expect(container.read(deleteListingControllerProvider).hasError, isTrue);
    });
  });
}
