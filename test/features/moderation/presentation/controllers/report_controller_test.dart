import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/moderation/data/moderation_repository.dart';
import 'package:roomie/features/moderation/presentation/controllers/report_controller.dart';

import '../../fakes/fake_moderation_repository.dart';

void main() {
  group('ReportUserController', () {
    test('reporta y bloquea en una sola acción (CU-11)', () async {
      final fakeRepo = FakeModerationRepository();
      final container = ProviderContainer(
        overrides: [moderationRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final done = await container
          .read(reportUserControllerProvider.notifier)
          .reportAndBlock(
            reportedUserId: 'user-2',
            reportedListingId: 'l1',
            reasons: const ['Spam', 'Estafa'],
          );

      expect(done, isTrue);
      expect(fakeRepo.reports.single.userId, 'user-2');
      expect(fakeRepo.reports.single.listingId, 'l1');
      expect(fakeRepo.reports.single.reasons, ['Spam', 'Estafa']);
      // Postcondición: el reportado queda bloqueado para quien reporta.
      expect(fakeRepo.blockedIds, contains('user-2'));
      expect(
        await container.read(blockedUserIdsProvider.future),
        contains('user-2'),
      );
    });

    test('deja estado de error si falla', () async {
      final fakeRepo = FakeModerationRepository(
        reportError: Exception('fallo'),
      );
      final container = ProviderContainer(
        overrides: [moderationRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final done = await container
          .read(reportUserControllerProvider.notifier)
          .reportAndBlock(reportedUserId: 'user-2', reasons: const ['Spam']);

      expect(done, isFalse);
      expect(container.read(reportUserControllerProvider).hasError, isTrue);
    });
  });
}
