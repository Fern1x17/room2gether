import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/auth/presentation/controllers/sign_out_controller.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  group('SignOutController', () {
    test('signOut() cierra sesión y devuelve true', () async {
      final fakeRepo = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final ok = await container.read(signOutControllerProvider.notifier).signOut();

      expect(ok, isTrue);
      expect(fakeRepo.signedOut, isTrue);
      expect(container.read(signOutControllerProvider).hasValue, isTrue);
    });

    test('signOut() devuelve false y deja error si el repositorio falla', () async {
      final fakeRepo = FakeAuthRepository(signOutError: Exception('fallo'));
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final ok = await container.read(signOutControllerProvider.notifier).signOut();

      expect(ok, isFalse);
      expect(container.read(signOutControllerProvider).hasError, isTrue);
    });
  });
}
