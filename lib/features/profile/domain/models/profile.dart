class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.age,
    this.bio,
    this.avatarUrl,
    this.city,
    this.budgetMin,
    this.budgetMax,
    required this.isSmoker,
    required this.hasPets,
    this.cleanlinessLevel,
    this.schedule,
    required this.isVerified,
  });

  final String id;
  final String displayName;
  final int age;
  final String? bio;
  final String? avatarUrl;
  final String? city;
  final int? budgetMin;
  final int? budgetMax;
  final bool isSmoker;
  final bool hasPets;
  final int? cleanlinessLevel;
  final String? schedule;
  final bool isVerified;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      age: map['age'] as int,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String?,
      budgetMin: map['budget_min'] as int?,
      budgetMax: map['budget_max'] as int?,
      isSmoker: map['is_smoker'] as bool,
      hasPets: map['has_pets'] as bool,
      cleanlinessLevel: map['cleanliness_level'] as int?,
      schedule: map['schedule'] as String?,
      isVerified: map['is_verified'] as bool,
    );
  }

  Profile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? city,
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
      age: age,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      isSmoker: isSmoker ?? this.isSmoker,
      hasPets: hasPets ?? this.hasPets,
      cleanlinessLevel: cleanlinessLevel ?? this.cleanlinessLevel,
      schedule: schedule ?? this.schedule,
      isVerified: isVerified,
    );
  }
}
