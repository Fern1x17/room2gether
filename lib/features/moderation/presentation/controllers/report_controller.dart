import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../data/moderation_repository.dart';

/// Bloqueados por el usuario actual y cuándo se bloqueó a cada uno.
final myBlocksProvider = FutureProvider<Map<String, DateTime>>((ref) {
  ref.watch(currentUserIdProvider); // caché por usuario: se tira al cambiar
  return ref.read(moderationRepositoryProvider).fetchMyBlocks();
});

/// Usuarios bloqueados por el usuario actual. El feed y el chat lo usan para
/// aplicar los efectos del bloqueo (no ver publicaciones, no chatear).
///
/// Derivado de [myBlocksProvider] para no repetir la consulta: quien solo
/// necesita saber "¿está bloqueado?" usa este.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final blocks = await ref.watch(myBlocksProvider.future);
  return blocks.keys.toSet();
});

class ReportUserController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Reporta y bloquea en una sola acción (paso 3 de CU-11).
  /// Devuelve `true` si se completó.
  Future<bool> reportAndBlock({
    required String reportedUserId,
    String? reportedListingId,
    required List<String> reasons,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(moderationRepositoryProvider)
          .reportAndBlock(
            reportedUserId: reportedUserId,
            reportedListingId: reportedListingId,
            reasons: reasons,
          );
      ref.invalidate(myBlocksProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudo enviar el reporte. Inténtalo de nuevo.',
        stackTrace,
      );
      return false;
    }
  }
}

final reportUserControllerProvider =
    AsyncNotifierProvider<ReportUserController, void>(ReportUserController.new);
