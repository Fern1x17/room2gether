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
    // RLS ya limita las filas a las del propio usuario (blocks_select_own).
    final rows = await _client.from('blocks').select('blocked_id');
    return rows.map((row) => row['blocked_id'] as String).toSet();
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return SupabaseModerationRepository(supabase);
});
