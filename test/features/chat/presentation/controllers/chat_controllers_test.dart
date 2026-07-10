import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/presentation/controllers/chat_controllers.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';

import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../fakes/fake_chat_repository.dart';

ProviderContainer _container(
  FakeChatRepository fakeRepo, {
  FakeModerationRepository? moderationRepo,
}) {
  final container = ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(fakeRepo),
      moderationRepositoryProvider.overrideWithValue(
        moderationRepo ?? FakeModerationRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('OpenConversationController', () {
    test('crea la conversación si no existe (postcondición CU-10)', () async {
      final fakeRepo = FakeChatRepository();
      final container = _container(fakeRepo);

      final conversation = await container
          .read(openConversationControllerProvider.notifier)
          .open(otherUserId: 'user-2', listingId: 'l1');

      expect(conversation, isNotNull);
      expect(fakeRepo.createdConversations, 1);
      expect(conversation!.listingId, 'l1');
    });

    test('reutiliza la conversación existente entre los 2 usuarios', () async {
      final fakeRepo = FakeChatRepository(
        conversations: [fakeConversation(id: 'conv-1', otherUserId: 'user-2')],
      );
      final container = _container(fakeRepo);

      final conversation = await container
          .read(openConversationControllerProvider.notifier)
          .open(otherUserId: 'user-2');

      expect(conversation!.id, 'conv-1');
      expect(fakeRepo.createdConversations, 0);
    });

    test('deja estado de error si falla', () async {
      final fakeRepo = FakeChatRepository(openError: Exception('fallo'));
      final container = _container(fakeRepo);

      final conversation = await container
          .read(openConversationControllerProvider.notifier)
          .open(otherUserId: 'user-2');

      expect(conversation, isNull);
      expect(
        container.read(openConversationControllerProvider).hasError,
        isTrue,
      );
    });

    test('no abre chat con un usuario bloqueado (efecto CU-11)', () async {
      final fakeRepo = FakeChatRepository();
      final container = _container(
        fakeRepo,
        moderationRepo: FakeModerationRepository(blockedIds: {'user-2'}),
      );

      final conversation = await container
          .read(openConversationControllerProvider.notifier)
          .open(otherUserId: 'user-2');

      expect(conversation, isNull);
      expect(fakeRepo.createdConversations, 0);
      final state = container.read(openConversationControllerProvider);
      expect(state.error, 'Has bloqueado a este usuario.');
    });
  });

  group('SendMessageController', () {
    test('envía el mensaje recortado', () async {
      final fakeRepo = FakeChatRepository();
      final container = _container(fakeRepo);

      final sent = await container
          .read(sendMessageControllerProvider.notifier)
          .send(conversationId: 'conv-1', content: '  Hola  ');

      expect(sent, isTrue);
      expect(fakeRepo.sentMessages.single.content, 'Hola');
    });

    test('no envía mensajes vacíos', () async {
      final fakeRepo = FakeChatRepository();
      final container = _container(fakeRepo);

      final sent = await container
          .read(sendMessageControllerProvider.notifier)
          .send(conversationId: 'conv-1', content: '   ');

      expect(sent, isFalse);
      expect(fakeRepo.sentMessages, isEmpty);
    });

    test('deja estado de error si falla el envío', () async {
      final fakeRepo = FakeChatRepository(sendError: Exception('fallo'));
      final container = _container(fakeRepo);

      final sent = await container
          .read(sendMessageControllerProvider.notifier)
          .send(conversationId: 'conv-1', content: 'Hola');

      expect(sent, isFalse);
      expect(container.read(sendMessageControllerProvider).hasError, isTrue);
    });
  });

  group('messagesStreamProvider', () {
    test('emite los mensajes del stream del repositorio', () async {
      final fakeRepo = FakeChatRepository();
      final container = _container(fakeRepo);

      final firstEmission = container.read(
        messagesStreamProvider('conv-1').future,
      );
      fakeRepo.messagesController.add([fakeMessage(content: 'Hola')]);

      final messages = await firstEmission;
      expect(messages.single.content, 'Hola');
    });
  });
}
