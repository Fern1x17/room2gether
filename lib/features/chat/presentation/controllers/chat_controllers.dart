import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

/// Conversaciones del usuario autenticado (pantalla "Chats").
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  ref.watch(currentUserIdProvider); // caché por usuario: se tira al cambiar
  return ref.read(chatRepositoryProvider).fetchMyConversations();
});

/// Cabecera del chat (nombre del otro participante).
final conversationProvider = FutureProvider.family<Conversation, String>((
  ref,
  id,
) {
  return ref.read(chatRepositoryProvider).fetchConversation(id);
});

/// Mensajes en vivo de una conversación.
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  return ref.read(chatRepositoryProvider).watchMessages(conversationId);
});

/// Abre (o crea) la conversación con el dueño de una publicación (CU-10).
class OpenConversationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Devuelve la conversación, o `null` si falló.
  Future<Conversation?> open({
    required String otherUserId,
    String? listingId,
  }) async {
    state = const AsyncLoading();
    try {
      // Efecto del bloqueo (CU-11): no se puede chatear con un bloqueado.
      final blocked = await ref
          .read(moderationRepositoryProvider)
          .fetchMyBlockedIds();
      if (blocked.contains(otherUserId)) {
        state = AsyncError('Has bloqueado a este usuario.', StackTrace.current);
        return null;
      }
      final conversation = await ref
          .read(chatRepositoryProvider)
          .openConversation(otherUserId: otherUserId, listingId: listingId);
      ref.invalidate(conversationsProvider);
      state = const AsyncData(null);
      return conversation;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo abrir el chat. Inténtalo de nuevo.',
        stackTrace,
      );
      return null;
    }
  }
}

final openConversationControllerProvider =
    AsyncNotifierProvider<OpenConversationController, void>(
      OpenConversationController.new,
    );

class SendMessageController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> send({
    required String conversationId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversationId, content: trimmed);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo enviar el mensaje. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }
}

final sendMessageControllerProvider =
    AsyncNotifierProvider<SendMessageController, void>(
      SendMessageController.new,
    );

class MessageActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> deleteMessage(String messageId) async {
    state = const AsyncLoading();
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError('No se pudo borrar el mensaje.', stackTrace);
      return false;
    }
  }

  Future<bool> updateMessage(String messageId, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateMessage(messageId: messageId, newContent: trimmed);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError('No se pudo editar el mensaje.', stackTrace);
      return false;
    }
  }
}

final messageActionsControllerProvider =
    AsyncNotifierProvider<MessageActionsController, void>(
      MessageActionsController.new,
    );
