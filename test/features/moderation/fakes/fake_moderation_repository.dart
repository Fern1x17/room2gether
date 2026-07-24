import 'package:room2gether/features/moderation/data/moderation_repository.dart';

class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({
    Set<String>? blockedIds,
    this.reportError,
    this.blockedAt,
  }) : blockedIds = blockedIds ?? {};

  final Set<String> blockedIds;

  /// Fecha de bloqueo de cada id. Los que no estén aquí se dan por bloqueados
  /// "desde siempre", que es lo cómodo para los tests que no miran la fecha.
  final Map<String, DateTime>? blockedAt;
  final Object? reportError;
  final List<({String userId, String? listingId, List<String> reasons})>
  reports = [];

  @override
  Future<void> reportAndBlock({
    required String reportedUserId,
    String? reportedListingId,
    required List<String> reasons,
  }) async {
    if (reportError != null) throw reportError!;
    reports.add((
      userId: reportedUserId,
      listingId: reportedListingId,
      reasons: reasons,
    ));
    blockedIds.add(reportedUserId);
  }

  @override
  Future<Set<String>> fetchMyBlockedIds() async => blockedIds;

  @override
  Future<Map<String, DateTime>> fetchMyBlocks() async {
    return {
      for (final id in blockedIds)
        id: blockedAt?[id] ?? DateTime.fromMillisecondsSinceEpoch(0),
    };
  }
}
