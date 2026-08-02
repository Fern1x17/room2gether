import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/domain/auth_failure.dart';
import 'package:room2gether/features/auth/presentation/controllers/login_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  group('LoginController', () {
    test(
      'estado pasa a data y devuelve AuthResponse en un login correcto',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        final response = await container
            .read(loginControllerProvider.notifier)
            .login(email: 'test@example.com', password: 'password123');

        expect(response, isNotNull);
        expect(response!.session, isNotNull);
        expect(container.read(loginControllerProvider).hasValue, isTrue);
      },
    );

    test(
      'estado pasa a error y devuelve null con credenciales incorrectas',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                signInError: const AuthException('Invalid login credentials'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final response = await container
            .read(loginControllerProvider.notifier)
            .login(email: 'test@example.com', password: 'wrong-password');

        expect(response, isNull);
        final state = container.read(loginControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.error.toString(), 'Email o contraseña incorrectos.');
        expect((state.error! as AuthFailure).emailNotConfirmed, isFalse);
      },
    );

    test('marca emailNotConfirmed si la cuenta está sin confirmar', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              signInError: const AuthException(
                'Email not confirmed',
                code: 'email_not_confirmed',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(loginControllerProvider.notifier)
          .login(email: 'test@example.com', password: 'password123');

      final error = container.read(loginControllerProvider).error;
      expect((error! as AuthFailure).emailNotConfirmed, isTrue);
      expect(
        error.toString(),
        'Debes confirmar tu email antes de iniciar sesión.',
      );
    });
  });
}
