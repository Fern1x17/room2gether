/// Un usuario bloqueado por el usuario actual, con lo necesario para pintarlo
/// en la lista de bloqueados (CU-11, desbloqueo).
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.blockedAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime blockedAt;

  /// [map] es una fila de `blocks` con el perfil embebido:
  /// `select('blocked_id, created_at, blocked:profiles!blocks_blocked_id_fkey(...)')`.
  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    final profile = map['blocked'] as Map<String, dynamic>;
    return BlockedUser(
      id: profile['id'] as String,
      displayName: profile['display_name'] as String,
      avatarUrl: profile['avatar_url'] as String?,
      blockedAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
