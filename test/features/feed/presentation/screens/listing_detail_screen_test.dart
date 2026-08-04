import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/feed/presentation/screens/listing_detail_screen.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';

import '../../../chat/fakes/fake_chat_repository.dart';
import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../fakes/fake_feed_repository.dart';

Widget _wrap({required FakeFeedRepository feedRepo, String? currentUserId}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(currentUserId ?? 'user-1'),
      feedRepositoryProvider.overrideWithValue(feedRepo),
      chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
      moderationRepositoryProvider.overrideWithValue(
        FakeModerationRepository(),
      ),
    ],
    child: const MaterialApp(home: ListingDetailScreen(listingId: 'listing-1')),
  );
}

void main() {
  group('ListingDetailScreen', () {
    testWidgets('muestra la publicación cuando carga', (tester) async {
      await tester.pumpWidget(
        _wrap(
          feedRepo: FakeFeedRepository(
            listings: [
              fakeListing(ownerId: 'user-2', title: 'Habitación luminosa'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habitación luminosa'), findsOneWidget);
      // Publicación ajena: el menú de reportar (CU-11) está disponible.
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    // Regresión: con `listingAsync.value` el build relanzaba el error de la
    // carga y la pantalla reventaba, así que la rama `error:` del `when` no
    // llegaba a pintarse nunca.
    testWidgets(
      'un fallo de carga pinta el error en vez de romper la pantalla',
      (tester) async {
        await tester.pumpWidget(
          _wrap(feedRepo: FakeFeedRepository(fetchError: Exception('caída'))),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('No se pudo cargar la publicación.'), findsOneWidget);
      },
    );

    testWidgets('si la carga falla no se ofrece el menú de opciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          feedRepo: FakeFeedRepository(fetchError: Exception('caída')),
          currentUserId: 'user-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
