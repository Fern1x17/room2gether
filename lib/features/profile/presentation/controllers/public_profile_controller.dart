import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../../feed/data/feed_repository.dart';
import '../../../feed/domain/models/listing.dart';
import '../../data/public_profile_repository.dart';
import '../../domain/models/public_profile.dart';

/// Perfil público de otro usuario (CU-19). `null` si el usuario no existe.
///
/// `autoDispose` porque se consulta por id y no tiene sentido guardar en caché
/// todos los perfiles visitados; `family` para poder abrir varios.
final publicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile?, String>((ref, userId) {
      // Al cambiar de cuenta cambian los bloqueos, y con ellos lo que se ve.
      ref.watch(currentUserIdProvider);
      return ref.read(publicProfileRepositoryProvider).fetchPublicProfile(
        userId,
      );
    });

/// Publicaciones activas del usuario cuyo perfil se está viendo (CU-19).
/// Solo se consulta cuando el perfil es visible: con bloqueo de por medio la
/// pantalla ni siquiera lo pide.
final userListingsProvider = FutureProvider.autoDispose
    .family<List<Listing>, String>((ref, userId) {
      ref.watch(currentUserIdProvider);
      return ref.read(feedRepositoryProvider).fetchListingsByOwner(userId);
    });
