import 'package:room2gether/features/profile/data/public_profile_repository.dart';
import 'package:room2gether/features/profile/domain/models/public_profile.dart';

PublicProfile fakePublicProfile({
  String id = 'user-2',
  bool isVisible = true,
  bool isBlockedByMe = false,
  String? displayName = 'Ana',
  String? avatarUrl,
  String? bio = 'Busco piso céntrico',
  String? cityName = 'Vigo',
  int? budgetMin = 300,
  int? budgetMax = 500,
  bool? isSmoker = false,
  bool? hasPets = true,
  int? cleanlinessLevel = 4,
  String? schedule = 'night_owl',
}) {
  return PublicProfile(
    id: id,
    isVisible: isVisible,
    isBlockedByMe: isBlockedByMe,
    displayName: displayName,
    avatarUrl: avatarUrl,
    bio: bio,
    cityName: cityName,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    isSmoker: isSmoker,
    hasPets: hasPets,
    cleanlinessLevel: cleanlinessLevel,
    schedule: schedule,
  );
}

/// Perfil tal y como lo devuelve la RPC con un bloqueo de por medio.
/// Con bloqueo PROPIO devuelve el nombre —y solo el nombre—, para
/// poder decir a quién se está desbloqueando. Si el bloqueo es del otro, no
/// llega ni eso.
PublicProfile fakeBlockedPublicProfile({
  String id = 'user-2',
  bool isBlockedByMe = true,
  String displayName = 'Ana',
}) {
  return PublicProfile(
    id: id,
    isVisible: false,
    isBlockedByMe: isBlockedByMe,
    displayName: isBlockedByMe ? displayName : null,
  );
}

class FakePublicProfileRepository implements PublicProfileRepository {
  FakePublicProfileRepository({this.profile, this.error});

  final PublicProfile? profile;
  final Object? error;

  final List<String> requestedIds = [];

  @override
  Future<PublicProfile?> fetchPublicProfile(String userId) async {
    requestedIds.add(userId);
    if (error != null) throw error!;
    return profile;
  }
}
