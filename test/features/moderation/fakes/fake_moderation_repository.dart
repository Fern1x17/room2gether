import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/moderation/domain/models/blocked_user.dart';

class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({
    Set<String>? blockedIds,
    this.reportError,
    this.blockedAt,
    this.blockedUsers = const [],
    this.unblockError,
    this.blockError,
    this.blocksError,
  }) : blockedIds = blockedIds ?? {};

  final Set<String> blockedIds;

  /// Fecha de bloqueo de cada id. Los que no estén aquí se dan por bloqueados
  /// "desde siempre", que es lo cómodo para los tests que no miran la fecha.
  final Map<String, DateTime>? blockedAt;
  final Object? reportError;
  final Object? unblockError;
  final Object? blockError;

  /// Fallo al consultar los bloqueos (lo usan feed y chat para aplicar los
  /// efectos del bloqueo).
  final Object? blocksError;
  List<BlockedUser> blockedUsers;
  final List<String> unblockedIds = [];
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
  Future<Set<String>> fetchMyBlockedIds() async {
    if (blocksError != null) throw blocksError!;
    return blockedIds;
  }

  @override
  Future<Map<String, DateTime>> fetchMyBlocks() async {
    if (blocksError != null) throw blocksError!;
    return {
      for (final id in blockedIds)
        id: blockedAt?[id] ?? DateTime.fromMillisecondsSinceEpoch(0),
    };
  }

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async => blockedUsers;

  @override
  Future<void> blockUser(String blockedId) async {
    if (blockError != null) throw blockError!;
    blockedIds.add(blockedId);
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    if (unblockError != null) throw unblockError!;
    unblockedIds.add(blockedId);
    blockedIds.remove(blockedId);
    blockedUsers = blockedUsers.where((u) => u.id != blockedId).toList();
  }
}
