import 'dart:async';

import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/domain/models/conversation.dart';
import 'package:room2gether/features/chat/domain/models/message.dart';

Conversation fakeConversation({
  String id = 'conv-1',
  String otherUserId = 'user-2',
  String otherName = 'Ana',
  String? listingId,
}) {
  return Conversation(
    id: id,
    listingId: listingId,
    otherUser: ChatParticipant(id: otherUserId, displayName: otherName),
  );
}

Message fakeMessage({
  String id = 'msg-1',
  String conversationId = 'conv-1',
  String senderId = 'user-1',
  String content = 'Hola',
}) {
  return Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    content: content,
    createdAt: DateTime(2026, 7, 7),
  );
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    List<Conversation>? conversations,
    this.sendError,
    this.openError,
    this.deleteError,
    this.updateError,
    this.conversationError,
    this.unreadCountsError,
  }) : conversations = conversations ?? [];

  final List<Conversation> conversations;
  final Object? sendError;
  final Object? openError;
  final Object? deleteError;
  final Object? updateError;
  final Object? conversationError;
  final Object? unreadCountsError;
  final List<({String conversationId, String content})> sentMessages = [];
  final List<String> deletedMessageIds = [];
  final List<({String messageId, String newContent})> updatedMessages = [];
  final messagesController = StreamController<List<Message>>.broadcast();
  int createdConversations = 0;

  /// Contadores que devuelve [fetchUnreadCounts]. Se puede cambiar entre
  /// emisiones de [inboxController] para simular que llega un mensaje.
  Map<String, int> unreadCounts = const {};
  final inboxController = StreamController<void>.broadcast();
  final List<String> readConversationIds = [];
  int unreadFetches = 0;

  @override
  Future<Conversation> openConversation({
    required String otherUserId,
    String? listingId,
  }) async {
    if (openError != null) throw openError!;
    final existing = conversations
        .where((c) => c.otherUser.id == otherUserId)
        .firstOrNull;
    if (existing != null) return existing;
    createdConversations++;
    final created = fakeConversation(
      id: 'conv-new-$createdConversations',
      otherUserId: otherUserId,
      listingId: listingId,
    );
    conversations.add(created);
    return created;
  }

  @override
  Future<List<Conversation>> fetchMyConversations() async => conversations;

  @override
  Future<Conversation> fetchConversation(String id) async {
    if (conversationError != null) throw conversationError!;
    return conversations.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    if (sendError != null) throw sendError!;
    sentMessages.add((conversationId: conversationId, content: content));
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return messagesController.stream;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    if (deleteError != null) throw deleteError!;
    deletedMessageIds.add(messageId);
  }

  @override
  Future<void> updateMessage({
    required String messageId,
    required String newContent,
  }) async {
    if (updateError != null) throw updateError!;
    updatedMessages.add((messageId: messageId, newContent: newContent));
  }

  @override
  Future<Map<String, int>> fetchUnreadCounts() async {
    unreadFetches++;
    if (unreadCountsError != null) throw unreadCountsError!;
    return unreadCounts;
  }

  @override
  Stream<void> watchInboxChanges() => inboxController.stream;

  @override
  Future<void> markConversationRead(String conversationId) async {
    readConversationIds.add(conversationId);
    unreadCounts = {...unreadCounts}..remove(conversationId);
  }
}
