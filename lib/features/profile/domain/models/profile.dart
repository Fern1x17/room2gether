class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.birthdate,
    this.bio,
    this.avatarUrl,
    this.cityId,
    this.cityName,
    this.budgetMin,
    this.budgetMax,
    required this.isSmoker,
    required this.hasPets,
    this.cleanlinessLevel,
    this.schedule,
    required this.isVerified,
    required this.role,
  });

  final String id;
  final String displayName;
  final DateTime birthdate;
  final String? bio;
  final String? avatarUrl;
  final String? cityId;
  final String? cityName; // solo lectura (join con cities), no se escribe
  final int? budgetMin;
  final int? budgetMax;
  final bool isSmoker;
  final bool hasPets;
  final int? cleanlinessLevel;
  final String? schedule;
  final bool isVerified;
  final String role; // 'user' | 'moderator'

  bool get isModerator => role == 'moderator';

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      birthdate: DateTime.parse(map['birthdate'] as String),
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      cityId: map['city_id'] as String?,
      cityName: (map['city'] as Map<String, dynamic>?)?['name'] as String?,
      budgetMin: map['budget_min'] as int?,
      budgetMax: map['budget_max'] as int?,
      isSmoker: map['is_smoker'] as bool,
      hasPets: map['has_pets'] as bool,
      cleanlinessLevel: map['cleanliness_level'] as int?,
      schedule: map['schedule'] as String?,
      isVerified: map['is_verified'] as bool,
      role: map['role'] as String,
    );
  }

  static const Object _unset = Object();

  // birthdate, isVerified y role no son editables por el usuario: la fecha de
  // nacimiento se fija en el registro y el rol lo gestiona el servidor.
  // cityId/cityName usan centinela para poder LIMPIAR la ciudad (null real).
  Profile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    Object? cityId = _unset,
    Object? cityName = _unset,
    int? budgetMin,
    int? budgetMax,
    bool? isSmoker,
    bool? hasPets,
    int? cleanlinessLevel,
    String? schedule,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      birthdate: birthdate,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cityId: identical(cityId, _unset) ? this.cityId : cityId as String?,
      cityName: identical(cityName, _unset)
          ? this.cityName
          : cityName as String?,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      isSmoker: isSmoker ?? this.isSmoker,
      hasPets: hasPets ?? this.hasPets,
      cleanlinessLevel: cleanlinessLevel ?? this.cleanlinessLevel,
      schedule: schedule ?? this.schedule,
      isVerified: isVerified,
      role: role,
    );
  }
}
