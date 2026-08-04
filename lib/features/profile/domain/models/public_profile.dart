/// Perfil de OTRO usuario tal y como lo devuelve `get_public_profile` (CU-19).
///
/// Solo trae los campos que su dueño puede cambiar en la pestaña Perfil. No
/// es un [Profile] recortado: aquí todos los datos son opcionales porque con
/// un bloqueo de por medio la RPC los devuelve a null, y eso es un estado
/// legítimo de la pantalla, no un error.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.isVisible,
    required this.isBlockedByMe,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.cityName,
    this.budgetMin,
    this.budgetMax,
    this.isSmoker,
    this.hasPets,
    this.cleanlinessLevel,
    this.schedule,
  });

  final String id;

  /// `false` si hay bloqueo en cualquiera de los dos sentidos. Cuando es
  /// `false`, el resto de campos vienen vacíos desde la base de datos.
  final bool isVisible;

  /// El bloqueo lo puso el usuario actual, así que puede deshacerlo.
  final bool isBlockedByMe;

  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? cityName;
  final int? budgetMin;
  final int? budgetMax;
  final bool? isSmoker;
  final bool? hasPets;
  final int? cleanlinessLevel;
  final String? schedule;

  /// Nombre a mostrar, con recambio para los perfiles sin nombre.
  String get displayNameLabel {
    final name = displayName?.trim() ?? '';
    return name.isEmpty ? 'Usuario' : name;
  }

  /// Rango de presupuesto en texto, o `null` si no lo ha rellenado.
  String? get budgetLabel {
    if (budgetMin != null && budgetMax != null) {
      return '$budgetMin € - $budgetMax € al mes';
    }
    if (budgetMin != null) return 'Desde $budgetMin € al mes';
    if (budgetMax != null) return 'Hasta $budgetMax € al mes';
    return null;
  }

  factory PublicProfile.fromMap(Map<String, dynamic> map) {
    return PublicProfile(
      id: map['id'] as String,
      isVisible: map['is_visible'] as bool,
      isBlockedByMe: map['is_blocked_by_me'] as bool,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      cityName: map['city_name'] as String?,
      budgetMin: map['budget_min'] as int?,
      budgetMax: map['budget_max'] as int?,
      isSmoker: map['is_smoker'] as bool?,
      hasPets: map['has_pets'] as bool?,
      cleanlinessLevel: map['cleanliness_level'] as int?,
      schedule: map['schedule'] as String?,
    );
  }
}
