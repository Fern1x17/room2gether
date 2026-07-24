import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/profile.dart';

class ProfileController extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() {
    ref.watch(currentUserIdProvider); // caché por usuario: se tira al cambiar
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
      state = AsyncError(
        'No se pudo guardar el perfil. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }

  /// Sube la foto, guarda su URL en profiles.avatar_url en el momento (no
  /// espera a "Guardar cambios", para que la foto persista aunque el usuario
  /// salga sin guardar el formulario) y devuelve la URL pública, o `null` si
  /// algo falla.
  Future<String?> uploadAvatar({
    required Uint8List bytes,
    String extension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    final current = state.value;
    if (current == null) {
      return null;
    }
    try {
      final repository = ref.read(profileRepositoryProvider);
      final url = await repository.uploadAvatar(
        userId: current.id,
        bytes: bytes,
        previousAvatarUrl: current.avatarUrl,
        extension: extension,
        contentType: contentType,
      );
      final updated = current.copyWith(avatarUrl: url);
      await repository.updateProfile(updated);
      state = AsyncData(updated);
      return url;
    } catch (_) {
      return null;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile>(ProfileController.new);
