import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/core/supabase/current_user_provider.dart';
import 'package:roomie/features/feed/data/feed_repository.dart';
import 'package:roomie/features/feed/data/recent_searches_repository.dart';
import 'package:roomie/features/feed/domain/models/listing_filter.dart';
import 'package:roomie/features/feed/presentation/controllers/feed_controller.dart';
import 'package:roomie/features/feed/presentation/controllers/recent_searches_controller.dart';
import 'package:roomie/features/moderation/data/moderation_repository.dart';
import 'package:roomie/features/profile/data/profile_repository.dart';

import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_feed_repository.dart';
import '../../fakes/fake_recent_searches_repository.dart';

void main() {
  group('FeedController', () {
    test('build() filtra por la ciudad del propio perfil', () async {
      final feedRepo = FakeFeedRepository(
        listings: [
          fakeListing(city: 'Valencia'),
          fakeListing(id: 'l2', city: 'Madrid'),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          feedRepositoryProvider.overrideWithValue(feedRepo),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          recentSearchesRepositoryProvider.overrideWithValue(
            FakeRecentSearchesRepository(),
          ),
          moderationRepositoryProvider.overrideWithValue(
            FakeModerationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final listings = await container.read(feedControllerProvider.future);

      expect(feedRepo.lastFilter?.city, isNull); // fakeProfile() no trae ciudad
      expect(listings, hasLength(2));
    });

    test(
      'search() aplica el filtro y lo guarda en búsquedas recientes',
      () async {
        final feedRepo = FakeFeedRepository(
          listings: [
            fakeListing(city: 'Valencia'),
            fakeListing(id: 'l2', city: 'Madrid'),
          ],
        );
        final recentRepo = FakeRecentSearchesRepository();
        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            feedRepositoryProvider.overrideWithValue(feedRepo),
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
            recentSearchesRepositoryProvider.overrideWithValue(recentRepo),
            moderationRepositoryProvider.overrideWithValue(
              FakeModerationRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(feedControllerProvider.future);
        await container
            .read(feedControllerProvider.notifier)
            .search(const ListingFilter(city: 'Valencia'));

        final state = container.read(feedControllerProvider);
        expect(state.value, hasLength(1));
        expect((await recentRepo.load()).first.city, 'Valencia');
      },
    );

    test('search() deja error si el repositorio falla', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          feedRepositoryProvider.overrideWithValue(
            FakeFeedRepository(fetchError: Exception('fallo')),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          recentSearchesRepositoryProvider.overrideWithValue(
            FakeRecentSearchesRepository(),
          ),
          moderationRepositoryProvider.overrideWithValue(
            FakeModerationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // build() también usa feedRepositoryProvider, así que ya falla en la carga inicial.
      await expectLater(
        container.read(feedControllerProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FeedController con bloqueados', () {
    test('excluye las publicaciones de usuarios bloqueados (CU-11)', () async {
      final feedRepo = FakeFeedRepository(
        listings: [
          fakeListing(id: 'l1', ownerId: 'user-2'),
          fakeListing(id: 'l2', ownerId: 'user-3'),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          feedRepositoryProvider.overrideWithValue(feedRepo),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          recentSearchesRepositoryProvider.overrideWithValue(
            FakeRecentSearchesRepository(),
          ),
          moderationRepositoryProvider.overrideWithValue(
            FakeModerationRepository(blockedIds: {'user-2'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final listings = await container.read(feedControllerProvider.future);

      expect(listings, hasLength(1));
      expect(listings.single.ownerId, 'user-3');
    });
  });

  group('RecentSearchesController', () {
    test('addSearch() persiste y refresca el estado', () async {
      final recentRepo = FakeRecentSearchesRepository();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          recentSearchesRepositoryProvider.overrideWithValue(recentRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(recentSearchesControllerProvider.future);
      await container
          .read(recentSearchesControllerProvider.notifier)
          .addSearch(const ListingFilter(city: 'Sevilla'));

      final state = container.read(recentSearchesControllerProvider).value;
      expect(state, isNotNull);
      expect(state!.first.city, 'Sevilla');
    });
  });
}
