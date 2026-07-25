import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/blocked_user.dart';

abstract class ModerationRepository {
  /// CU-11 (paso 3): reportar y bloquear son una única acción.
  Future<void> reportAndBlock({
    required String reportedUserId,
    String? reportedListingId,
    required List<String> reasons,
  });

  /// Ids de los usuarios bloqueados por el usuario actual.
  Future<Set<String>> fetchMyBlockedIds();

  /// Bloqueados y **cuándo** se bloqueó a cada uno. La fecha hace falta para
  /// ocultar solo lo que llegó después del bloqueo, no la conversación previa.
  Future<Map<String, DateTime>> fetchMyBlocks();

  /// Bloqueados con su perfil (nombre, foto) y fecha, para la pantalla de
  /// gestión de bloqueados. Ordenados del más reciente al más antiguo.
  Future<List<BlockedUser>> fetchBlockedUsers();

  /// Desbloquea a [blockedId]: borra la fila de `blocks`. Solo afecta a los
  /// bloqueos del propio usuario (RLS `blocks_delete_own` + filtro explícito).
  Future<void> unblockUser(String blockedId);
}

class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> reportAndBlock({
    required String reportedUserId,
    String? reportedListingId,
    required List<String> reasons,
  }) async {
    final me = _client.auth.currentUser!.id;
    await _client.from('reports').insert({
      'reporter_id': me,
      'reported_user_id': reportedUserId,
      'reported_listing_id': reportedListingId,
      'reason': reasons.join(', '),
    });
    // upsert con ignoreDuplicates: volver a reportar al mismo usuario no debe
    // fallar por la PK compuesta de blocks.
    await _client
        .from('blocks')
        .upsert(
          {'blocker_id': me, 'blocked_id': reportedUserId},
          onConflict: 'blocker_id,blocked_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<Set<String>> fetchMyBlockedIds() async {
    return (await fetchMyBlocks()).keys.toSet();
  }

  @override
  Future<Map<String, DateTime>> fetchMyBlocks() async {
    // RLS ya limita las filas a las del propio usuario (blocks_select_own).
    final rows = await _client.from('blocks').select('blocked_id, created_at');
    return {
      for (final row in rows)
        row['blocked_id'] as String: DateTime.parse(
          row['created_at'] as String,
        ),
    };
  }

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async {
    // RLS limita a los bloqueos propios; el join trae el perfil del bloqueado.
    final rows = await _client
        .from('blocks')
        .select(
          'created_at, blocked:profiles!blocks_blocked_id_fkey'
          '(id, display_name, avatar_url)',
        )
        .order('created_at', ascending: false);
    return rows.map(BlockedUser.fromMap).toList();
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    final me = _client.auth.currentUser!.id;
    // Defensa en profundidad: RLS ya solo deja borrar los bloqueos propios,
    // pero el filtro por blocker_id lo hace explícito (igual que el chat).
    await _client
        .from('blocks')
        .delete()
        .eq('blocker_id', me)
        .eq('blocked_id', blockedId);
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return SupabaseModerationRepository(supabase);
});
