import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/auth/presentation/controllers/login_controller.dart';
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
        expect(state.error, 'Email o contraseña incorrectos.');
      },
    );
  });
}
