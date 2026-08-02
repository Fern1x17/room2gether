import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/router/app_router.dart';
import 'package:room2gether/features/auth/data/auth_redirect.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/fakes/fake_auth_repository.dart';

/// El canje se fuerza a fallar para que la pantalla de callback no navegue a
/// `/onboarding` (que necesita medio Supabase montado). Lo que se comprueba
/// aquí es el enrutado: que el código de la URL de lanzamiento llega hasta el
/// repositorio.
Widget _app(
  FakeAuthRepository repository,
  AuthCallbackParams launchParams, {
  String initialLocation = '/',
  bool isWeb = true,
}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      routerConfig: buildAppRouter(
        initialLocation: initialLocation,
        launchParams: launchParams,
        isWeb: isWeb,
      ),
    ),
  );
}

void main() {
  group('enrutado del callback de confirmación', () {
    testWidgets('con code en la URL de lanzamiento arranca en el callback', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        exchangeError: const AuthException('bad code'),
      );

      await tester.pumpWidget(
        _app(repository, const AuthCallbackParams(code: 'abc123')),
      );
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 1);
    });

    testWidgets(
      'con token_hash en la URL de lanzamiento arranca en el callback',
      (tester) async {
        final repository = FakeAuthRepository(
          verifyError: const AuthException('bad token'),
        );

        await tester.pumpWidget(
          _app(
            repository,
            const AuthCallbackParams(tokenHash: 'tok123', type: 'signup'),
          ),
        );
        await tester.pumpAndSettle();

        expect(repository.verifyCallCount, 1);
        expect(repository.lastTokenHash, 'tok123');
        expect(repository.lastTokenType, 'signup');
      },
    );

    testWidgets('con error en la URL avisa sin intentar el canje', (
      tester,
    ) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        _app(
          repository,
          const AuthCallbackParams(
            errorDescription: 'Email link is invalid or has expired',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 0);
      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);
    });

    testWidgets('sin parámetros arranca donde diga initialLocation', (
      tester,
    ) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(_app(repository, const AuthCallbackParams()));
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 0);
      expect(find.text('Room2gether'), findsOneWidget);
    });

    testWidgets('abrir la ruta a mano, sin enlace, lleva al inicio', (
      tester,
    ) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        _app(
          repository,
          const AuthCallbackParams(),
          initialLocation: '/auth/callback',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Room2gether'), findsOneWidget);
      expect(find.text('Confirmando tu cuenta…'), findsNothing);
      expect(repository.verifyCallCount, 0);
    });

    testWidgets('fuera de la web la pantalla de confirmación no existe', (
      tester,
    ) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        _app(
          repository,
          const AuthCallbackParams(tokenHash: 'tok123', type: 'signup'),
          isWeb: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Room2gether'), findsOneWidget);
      expect(repository.verifyCallCount, 0);
    });
  });
}
