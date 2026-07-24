import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

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
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return SupabaseModerationRepository(supabase);
});
