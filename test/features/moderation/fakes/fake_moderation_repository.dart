import 'package:room2gether/features/moderation/data/moderation_repository.dart';

class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({Set<String>? blockedIds, this.reportError})
    : blockedIds = blockedIds ?? {};

  final Set<String> blockedIds;
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
}
