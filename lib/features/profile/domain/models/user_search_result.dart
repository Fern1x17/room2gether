/// Un usuario en la lista de resultados del buscador (CU-20).
///
/// Deliberadamente más pequeño que [Profile]: la RPC `search_profiles` solo
/// devuelve lo que se pinta en la fila del resultado. El perfil completo se
/// carga al abrirlo (CU-19).
class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.cityName,
    this.isBlocked = false,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? cityName;

  /// Bloqueado POR MÍ. Los que me han bloqueado a mí no llegan hasta aquí:
  /// la RPC los excluye, porque revertir eso no es decisión mía.
  final bool isBlocked;

  factory UserSearchResult.fromMap(Map<String, dynamic> map) {
    return UserSearchResult(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      cityName: map['city_name'] as String?,
      isBlocked: map['is_blocked'] as bool? ?? false,
    );
  }
}
