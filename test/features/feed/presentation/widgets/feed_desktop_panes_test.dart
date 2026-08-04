import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/feed/data/recent_searches_repository.dart';
import 'package:room2gether/features/feed/presentation/widgets/feed_desktop_panes.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';

import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_feed_repository.dart';
import '../../fakes/fake_recent_searches_repository.dart';

Widget _wrap(FakeFeedRepository feedRepo) {
  return ProviderScope(
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
    child: MaterialApp(
      home: Scaffold(body: FeedListPane(currentUri: Uri.parse('/feed'))),
    ),
  );
}

void main() {
  group('FeedListPane', () {
    testWidgets('cuenta las publicaciones cargadas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FakeFeedRepository(
            listings: [fakeListing(title: 'Habitación en el centro')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 publicaciones'), findsOneWidget);
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    // Regresión: con `listingsAsync.value` esta columna relanzaba el error del
    // feed y reventaba antes de construir ListingListView, que es quien pinta
    // el error y el botón de reintentar.
    testWidgets('un fallo del feed deja pintar el error de la lista', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FakeFeedRepository(fetchError: Exception('caída'))),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
      // Sin datos no hay contador que enseñar.
      expect(find.textContaining('publicaciones en'), findsNothing);
    });
  });
}
