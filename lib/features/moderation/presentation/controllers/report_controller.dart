import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/moderation_repository.dart';

/// Usuarios bloqueados por el usuario actual. El feed y el chat lo usan para
/// aplicar los efectos del bloqueo (no ver publicaciones, no chatear).
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(moderationRepositoryProvider).fetchMyBlockedIds();
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
      ref.invalidate(blockedUserIdsProvider);
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
