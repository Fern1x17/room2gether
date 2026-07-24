import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/profile.dart';

/// Nombre del bucket de Storage con las fotos de perfil.
const String kAvatarsBucket = 'avatars';

abstract class ProfileRepository {
  Future<Profile> fetchMyProfile();

  Future<void> updateProfile(Profile profile);

  /// Sube [bytes] (siempre JPEG ya recortado y redimensionado) y devuelve su
  /// URL pública. [previousAvatarUrl] es la foto que queda obsoleta, para
  /// borrarla del bucket.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String? previousAvatarUrl,
  });
}

/// Extrae la ruta dentro del bucket a partir de una URL pública de Storage
/// (`.../storage/v1/object/public/avatars/<userId>/<fichero>`).
///
/// Devuelve `null` si la URL no es de este bucket o no pertenece a [userId]:
/// así el borrado de la foto anterior nunca puede apuntar a la carpeta de otra
/// persona, aunque el valor guardado en `avatar_url` fuera inesperado.
@visibleForTesting
String? avatarStoragePathFromUrl(String? url, {required String userId}) {
  if (url == null) return null;
  const marker = '/object/public/$kAvatarsBucket/';
  final markerIndex = url.indexOf(marker);
  if (markerIndex == -1) return null;

  // Sin query (`?token=...`) ni fragmento: la ruta es solo el camino.
  final path = Uri.decodeComponent(
    url
        .substring(markerIndex + marker.length)
        .split('?')
        .first
        .split('#')
        .first,
  );
  if (!path.startsWith('$userId/') || path.contains('..')) return null;
  return path;
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile> fetchMyProfile() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('profiles')
        .select('*, city:cities(name)')
        .eq('id', userId)
        .single();
    return Profile.fromMap(row);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update({
          'display_name': profile.displayName,
          'bio': profile.bio,
          'avatar_url': profile.avatarUrl,
          'city_id': profile.cityId,
          'budget_min': profile.budgetMin,
          'budget_max': profile.budgetMax,
          'is_smoker': profile.isSmoker,
          'has_pets': profile.hasPets,
          'cleanliness_level': profile.cleanlinessLevel,
          'schedule': profile.schedule,
        })
        .eq('id', profile.id);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String? previousAvatarUrl,
  }) async {
    // Ruta única por subida (mismo patrón que las fotos de publicación). Antes
    // era fija (`{userId}/avatar.ext` con upsert), así que la URL pública no
    // cambiaba al reemplazar la foto y las cachés —la de Flutter, la del
    // navegador y la del CDN— seguían sirviendo la imagen anterior, también a
    // los demás usuarios. Con un nombre nuevo no hay nada que invalidar.
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await _client.storage
        .from(kAvatarsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Borrado de la foto anterior para no dejar huérfanos en el bucket. Es
    // "best effort": si falla, la subida ya es válida y no debe abortarse.
    final previousPath = avatarStoragePathFromUrl(
      previousAvatarUrl,
      userId: userId,
    );
    if (previousPath != null && previousPath != path) {
      try {
        await _client.storage.from(kAvatarsBucket).remove([previousPath]);
      } catch (_) {
        // Ignorado a propósito.
      }
    }

    return _client.storage.from(kAvatarsBucket).getPublicUrl(path);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(supabase);
});
