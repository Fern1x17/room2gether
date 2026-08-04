import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/public_profile.dart';

abstract class PublicProfileRepository {
  /// Perfil público de [userId] (CU-19), o `null` si no existe ese usuario.
  Future<PublicProfile?> fetchPublicProfile(String userId);
}

class SupabasePublicProfileRepository implements PublicProfileRepository {
  SupabasePublicProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PublicProfile?> fetchPublicProfile(String userId) async {
    // Vía RPC y no `select` directo: la política de `profiles` deja leer
    // cualquier perfil, así que quién ve qué se decide dentro de
    // `get_public_profile`, que es lo único capaz de mirar los bloqueos en
    // ambos sentidos.
    final rows = await _client.rpc<List<dynamic>>(
      'get_public_profile',
      params: {'p_user_id': userId},
    );
    if (rows.isEmpty) return null;
    return PublicProfile.fromMap(rows.first as Map<String, dynamic>);
  }
}

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) {
  return SupabasePublicProfileRepository(supabase);
});
