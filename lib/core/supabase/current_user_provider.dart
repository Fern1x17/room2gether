import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_client.dart';

/// Id del usuario autenticado, para que los widgets no llamen a Supabase
/// directamente (p. ej. distinguir publicaciones/mensajes propios).
///
/// Se auto-invalida cuando cambia el usuario de la sesión (cerrar sesión,
/// iniciar con otra cuenta). Los providers que cachean datos por-usuario
/// (perfil, feed, mis publicaciones, chats, bloqueados) hacen `ref.watch` de
/// este provider, de modo que un cambio de cuenta descarta sus cachés sin
/// necesidad de reiniciar la app.
final currentUserIdProvider = Provider<String?>((ref) {
  final currentId = supabase.auth.currentUser?.id;
  final subscription = supabase.auth.onAuthStateChange.listen((change) {
    final newId = change.session?.user.id;
    // Solo invalidar si el usuario realmente cambió: los eventos de refresco
    // de token o la sesión inicial no deben tirar las cachés (ni provocar un
    // bucle de invalidaciones).
    if (newId != currentId) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(subscription.cancel);
  return currentId;
});
