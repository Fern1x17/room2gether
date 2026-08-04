import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/presentation/screens/chat_screen.dart';
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
    child: const MaterialApp(home: ChatScreen(conversationId: 'conv-1')),
  );
}

/// El stream de mensajes no emite solo, así que `pumpAndSettle` se quedaría
/// esperando al spinner. Se pumpea a mano y se deja al stream emitir lo que
/// pida cada test.
Future<void> _pumpChat(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
}

void main() {
  group('ChatScreen', () {
    testWidgets('muestra el nombre del otro y sus mensajes', (tester) async {
      final chatRepo = FakeChatRepository(
        conversations: [fakeConversation(otherName: 'Ana')],
      );
      await _pumpChat(tester, _wrap(chatRepo: chatRepo));

      chatRepo.messagesController.add([fakeMessage(content: 'Hola')]);
      await tester.pump();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Hola'), findsOneWidget);
    });

    // Regresión: con `conversationAsync.value` el build relanzaba el error de
    // la cabecera y se llevaba por delante la pantalla entera, incluido el
    // `error:` del propio `when` de la cabecera.
    testWidgets('un fallo al cargar la conversación no rompe el chat', (
      tester,
    ) async {
      final chatRepo = FakeChatRepository(
        conversationError: Exception('caída'),
      );
      await _pumpChat(tester, _wrap(chatRepo: chatRepo));

      expect(tester.takeException(), isNull);
      // Cabecera de respaldo y chat utilizable pese al fallo.
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      // Sin saber quién es el otro, no se puede ofrecer reportarlo.
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('un fallo en los mensajes pinta su propio error', (
      tester,
    ) async {
      final chatRepo = FakeChatRepository(
        conversations: [fakeConversation(otherName: 'Ana')],
      );
      await _pumpChat(tester, _wrap(chatRepo: chatRepo));

      chatRepo.messagesController.addError(Exception('caída'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('No se pudieron cargar los mensajes.'), findsOneWidget);
      // La cabecera sigue funcionando: el fallo es solo de los mensajes.
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('un fallo al consultar los bloqueos no rompe el chat', (
      tester,
    ) async {
      final chatRepo = FakeChatRepository(
        conversations: [fakeConversation(otherName: 'Ana')],
      );
      await _pumpChat(
        tester,
        _wrap(
          chatRepo: chatRepo,
          moderationRepo: FakeModerationRepository(
            blocksError: Exception('caída'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Sin datos de bloqueo se sigue pudiendo escribir (que es lo que dice el
      // `?? const {}` de la pantalla).
      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
    });
  });
}
