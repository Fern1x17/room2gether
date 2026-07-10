import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/controllers/register_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  group('RegisterController', () {
    test(
      'estado pasa a data y devuelve AuthResponse en un registro correcto',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        final response = await container
            .read(registerControllerProvider.notifier)
            .register(
              email: 'test@example.com',
              password: 'password123',
              birthdate: DateTime(2000, 1, 1),
            );

        expect(response, isNotNull);
        expect(response!.session, isNotNull);
        expect(container.read(registerControllerProvider).hasValue, isTrue);
      },
    );

    test(
      'estado pasa a error y devuelve null si el repositorio falla',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                signUpError: const AuthException('User already registered'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final response = await container
            .read(registerControllerProvider.notifier)
            .register(
              email: 'test@example.com',
              password: 'password123',
              birthdate: DateTime(2000, 1, 1),
            );

        expect(response, isNull);
        final state = container.read(registerControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.error, 'Ya existe una cuenta con ese email.');
      },
    );

    test('devuelve response sin sesión si falta confirmar el email', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signUpWithoutSession: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final response = await container
          .read(registerControllerProvider.notifier)
          .register(
            email: 'test@example.com',
            password: 'password123',
            birthdate: DateTime(2000, 1, 1),
          );

      expect(response, isNotNull);
      expect(response!.session, isNull);
    });
  });
}
