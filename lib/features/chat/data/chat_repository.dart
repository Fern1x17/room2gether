import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/conversation.dart';
import '../domain/models/message.dart';

const _conversationColumns =
    '*, user_a_profile:profiles!conversations_user_a_fkey(id, display_name, avatar_url), '
    'user_b_profile:profiles!conversations_user_b_fkey(id, display_name, avatar_url)';

abstract class ChatRepository {
  Future<Conversation> openConversation({
    required String otherUserId,
    String? listingId,
  });

  Future<List<Conversation>> fetchMyConversations();

  Future<Conversation> fetchConversation(String id);

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  });

  Stream<List<Message>> watchMessages(String conversationId);

  Future<void> updateMessage({
    required String messageId,
    required String newContent,
  });

  Future<void> deleteMessage(String messageId);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;

  String get _myId => _client.auth.currentUser!.id;

  @override
  Future<Conversation> openConversation({
    required String otherUserId,
    String? listingId,
  }) async {
    final me = _myId;
    final existing = await _client
        .from('conversations')
        .select(_conversationColumns)
        .or(
          'and(user_a.eq.$me,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$me)',
        )
        .limit(1);
    if (existing.isNotEmpty) {
      return Conversation.fromMap(existing.first, currentUserId: me);
    }

    final created = await _client
        .from('conversations')
        .insert({'user_a': me, 'user_b': otherUserId, 'listing_id': listingId})
        .select(_conversationColumns)
        .single();
    return Conversation.fromMap(created, currentUserId: me);
  }

  @override
  Future<List<Conversation>> fetchMyConversations() async {
    final me = _myId;
    final rows = await _client
        .from('conversations')
        .select(_conversationColumns)
        .or('user_a.eq.$me,user_b.eq.$me')
        .order('updated_at', ascending: false);
    return rows
        .map((row) => Conversation.fromMap(row, currentUserId: me))
        .toList();
  }

  @override
  Future<Conversation> fetchConversation(String id) async {
    final row = await _client
        .from('conversations')
        .select(_conversationColumns)
        .eq('id', id)
        .single();
    return Conversation.fromMap(row, currentUserId: _myId);
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _myId,
      'content': content,
    });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Message.fromMap).toList());
  }

  @override
  Future<void> updateMessage({
    required String messageId,
    required String newContent,
  }) async {
    await _client
        .from('messages')
        .update({'content': newContent})
        .eq('id', messageId)
        .eq('sender_id', _myId);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    // Soft Delete: Actualiza el texto para que Supabase lo envíe por Realtime
    await _client
        .from('messages')
        .update({'content': '🚫 Este mensaje ha sido eliminado'})
        .eq('id', messageId)
        .eq('sender_id', _myId);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(supabase);
});