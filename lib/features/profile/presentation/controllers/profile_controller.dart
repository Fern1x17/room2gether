import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../domain/models/profile.dart';

class ProfileController extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() {
    final repository = ref.read(profileRepositoryProvider);
    return repository.fetchMyProfile();
  }

  Future<bool> save(Profile updated) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(updated);
      state = AsyncData(updated);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError('No se pudo guardar el perfil. Inténtalo de nuevo.', stackTrace);
      return false;
    }
  }

  /// Sube la foto y devuelve la URL pública, o `null` si falla.
  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final current = state.value;
    if (current == null) {
      return null;
    }
    try {
      final repository = ref.read(profileRepositoryProvider);
      return await repository.uploadAvatar(
        userId: current.id,
        bytes: bytes,
        fileExtension: fileExtension,
      );
    } catch (_) {
      return null;
    }
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, Profile>(
  ProfileController.new,
);
