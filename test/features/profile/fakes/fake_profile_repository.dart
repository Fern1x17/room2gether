import 'dart:typed_data';

import 'package:roomie/features/profile/data/profile_repository.dart';
import 'package:roomie/features/profile/domain/models/profile.dart';

Profile fakeProfile({
  String id = 'user-1',
  String displayName = 'Fernando',
  DateTime? birthdate,
  String role = 'user',
}) {
  return Profile(
    id: id,
    displayName: displayName,
    birthdate: birthdate ?? DateTime(2000, 1, 1),
    isSmoker: false,
    hasPets: false,
    isVerified: false,
    role: role,
  );
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    Profile? profile,
    this.fetchError,
    this.updateError,
    this.uploadAvatarUrl,
  }) : profile = profile ?? fakeProfile();

  Profile profile;
  final Object? fetchError;
  final Object? updateError;
  final String? uploadAvatarUrl;
  Profile? lastSavedProfile;

  @override
  Future<Profile> fetchMyProfile() async {
    if (fetchError != null) throw fetchError!;
    return profile;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    if (updateError != null) throw updateError!;
    lastSavedProfile = profile;
    this.profile = profile;
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    return uploadAvatarUrl ??
        'https://example.com/$userId/avatar.$fileExtension';
  }
}
