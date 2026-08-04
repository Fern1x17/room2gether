import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/user_search_result.dart';

abstract class UserSearchRepository {
  /// Busca perfiles por nombre (CU-20). Devuelve como mucho [limit] filas a
  /// partir de [offset].
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    required int limit,
    required int offset,
  });
}

class SupabaseUserSearchRepository implements UserSearchRepository {
  SupabaseUserSearchRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    required int limit,
    required int offset,
  }) async {
    // Toda la lógica vive en la RPC: es la única forma de excluir los bloqueos
    // en ambos sentidos (`blocks_select_own` oculta al cliente quién le ha
    // bloqueado a él) y de que el `limit` se aplique en la base de datos en
    // vez de sobre una lista ya traída entera.
    final rows = await _client.rpc<List<dynamic>>(
      'search_profiles',
      params: {'p_query': query, 'p_limit': limit, 'p_offset': offset},
    );
    return rows
        .map((row) => UserSearchResult.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

final userSearchRepositoryProvider = Provider<UserSearchRepository>((ref) {
  return SupabaseUserSearchRepository(supabase);
});
