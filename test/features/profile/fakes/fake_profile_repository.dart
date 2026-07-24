import 'dart:typed_data';

import 'package:room2gether/features/profile/data/profile_repository.dart';
import 'package:room2gether/features/profile/domain/models/profile.dart';

Profile fakeProfile({
  String id = 'user-1',
  String displayName = 'Fernando',
  DateTime? birthdate,
  String role = 'user',
  String? avatarUrl,
}) {
  return Profile(
    id: id,
    displayName: displayName,
    birthdate: birthdate ?? DateTime(2000, 1, 1),
    avatarUrl: avatarUrl,
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

  /// URL que se pasó como foto anterior en la última subida, para comprobar
  /// que el repositorio real podría borrarla.
  String? lastPreviousAvatarUrl;
  String? lastUploadExtension;
  String? lastUploadContentType;
  int uploadAvatarCalls = 0;

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
    String? previousAvatarUrl,
    String extension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    lastPreviousAvatarUrl = previousAvatarUrl;
    lastUploadExtension = extension;
    lastUploadContentType = contentType;
    uploadAvatarCalls++;
    // Sin URL fija, cada subida devuelve una distinta: es justo la propiedad
    // que arregla el bug de refresco.
    return uploadAvatarUrl ??
        'https://example.com/$userId/$uploadAvatarCalls.jpg';
  }
}
