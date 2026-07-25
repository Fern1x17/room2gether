import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/moderation/domain/models/blocked_user.dart';
import 'package:room2gether/features/moderation/presentation/controllers/report_controller.dart';

import '../../fakes/fake_moderation_repository.dart';

BlockedUser _blocked(String id) => BlockedUser(
  id: id,
  displayName: 'Usuario $id',
  blockedAt: DateTime(2026, 7, 20),
);

ProviderContainer _container(FakeModerationRepository fakeRepo) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      moderationRepositoryProvider.overrideWithValue(fakeRepo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('blockedUsersProvider', () {
    test('devuelve los bloqueados con su perfil', () async {
      final fakeRepo = FakeModerationRepository(
        blockedUsers: [_blocked('user-2'), _blocked('user-3')],
      );
      final container = _container(fakeRepo);

      final users = await container.read(blockedUsersProvider.future);

      expect(users.map((u) => u.id), ['user-2', 'user-3']);
    });
  });

  group('UnblockUserController', () {
    test('desbloquea y lo elimina de la lista', () async {
      final fakeRepo = FakeModerationRepository(
        blockedIds: {'user-2'},
        blockedUsers: [_blocked('user-2')],
      );
      final container = _container(fakeRepo);

      // Cargar el estado inicial.
      await container.read(blockedUsersProvider.future);

      final ok = await container
          .read(unblockUserControllerProvider.notifier)
          .unblock('user-2');

      expect(ok, isTrue);
      expect(fakeRepo.unblockedIds, ['user-2']);
      // Tras invalidar, la lista se recarga sin el desbloqueado.
      expect(await container.read(blockedUsersProvider.future), isEmpty);
      expect(await container.read(blockedUserIdsProvider.future), isEmpty);
    });

    test('deja estado de error si falla', () async {
      final fakeRepo = FakeModerationRepository(
        blockedIds: {'user-2'},
        blockedUsers: [_blocked('user-2')],
        unblockError: Exception('sin conexión'),
      );
      final container = _container(fakeRepo);

      final ok = await container
          .read(unblockUserControllerProvider.notifier)
          .unblock('user-2');

      expect(ok, isFalse);
      expect(container.read(unblockUserControllerProvider).hasError, isTrue);
      // No se tocó el bloqueo.
      expect(fakeRepo.blockedIds, contains('user-2'));
    });
  });
}
