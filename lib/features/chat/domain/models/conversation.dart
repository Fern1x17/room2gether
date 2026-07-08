/// El otro participante de una conversación, para mostrar nombre y avatar.
class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    this.listingId,
    required this.otherUser,
  });

  final String id;
  final String? listingId;
  final ChatParticipant otherUser;

  /// [currentUserId] decide cuál de los dos perfiles embebidos es "el otro".
  factory Conversation.fromMap(
    Map<String, dynamic> map, {
    required String currentUserId,
  }) {
    final userAProfile = map['user_a_profile'] as Map<String, dynamic>;
    final otherProfile = userAProfile['id'] == currentUserId
        ? map['user_b_profile'] as Map<String, dynamic>
        : userAProfile;
    return Conversation(
      id: map['id'] as String,
      listingId: map['listing_id'] as String?,
      otherUser: ChatParticipant.fromMap(otherProfile),
    );
  }
}
