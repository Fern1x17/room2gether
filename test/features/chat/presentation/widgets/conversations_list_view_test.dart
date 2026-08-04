import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/domain/models/conversation.dart';
import 'package:room2gether/features/chat/presentation/widgets/conversations_list_view.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';

import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../fakes/fake_chat_repository.dart';

Widget _wrap({
  required FakeChatRepository chatRepo,
  FakeModerationRepository? moderationRepo,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      chatRepositoryProvider.overrideWithValue(chatRepo),
      moderationRepositoryProvider.overrideWithValue(
        moderationRepo ?? FakeModerationRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: ConversationsListView(onConversationTap: (_) {})),
    ),
  );
}

void main() {
  group('ConversationsListView', () {
    testWidgets('lista las conversaciones con su contador', (tester) async {
      final chatRepo = FakeChatRepository(
        conversations: [fakeConversation(otherName: 'Ana')],
      )..unreadCounts = {'conv-1': 3};
      await tester.pumpWidget(_wrap(chatRepo: chatRepo));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    // Regresión: los bloqueados y el conteo son adornos de cada fila, pero con
    // `.value` su error se relanzaba en el build y se llevaba la lista entera,
    // que es el contenido de verdad de la pantalla.
    testWidgets('un fallo en los bloqueados no rompe la lista', (tester) async {
      await tester.pumpWidget(
        _wrap(
          chatRepo: FakeChatRepository(
            conversations: [fakeConversation(otherName: 'Ana')],
          ),
          moderationRepo: FakeModerationRepository(
            blocksError: Exception('caída'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bloqueado'), findsNothing);
    });

    testWidgets('un fallo en el conteo no rompe la lista', (tester) async {
      await tester.pumpWidget(
        _wrap(
          chatRepo: FakeChatRepository(
            conversations: [fakeConversation(otherName: 'Ana')],
            unreadCountsError: Exception('caída'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('un fallo al cargar los chats sí pinta su error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(chatRepo: _FailingConversationsRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudieron cargar tus chats.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
    });
  });
}

class _FailingConversationsRepository extends FakeChatRepository {
  @override
  Future<List<Conversation>> fetchMyConversations() async {
    throw Exception('caída');
  }
}
