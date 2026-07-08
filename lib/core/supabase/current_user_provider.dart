import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_client.dart';

/// Id del usuario autenticado, para que los widgets no llamen a Supabase
/// directamente (p. ej. distinguir publicaciones/mensajes propios).
final currentUserIdProvider = Provider<String?>((ref) {
  return supabase.auth.currentUser?.id;
});
