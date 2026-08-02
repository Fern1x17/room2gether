import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

/// Router mínimo con la pantalla y sus destinos, para comprobar a dónde lleva
/// cada botón sin arrancar toda la app.
GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => EmailConfirmationScreen(
          code: state.uri.queryParameters['code'],
          tokenHash: state.uri.queryParameters['token_hash'],
          type: state.uri.queryParameters['type'],
          errorDescription: state.uri.queryParameters['error_description'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(body: Text('ONBOARDING')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
}

Widget _wrap(FakeAuthRepository repository, String initialLocation) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: _router(initialLocation)),
  );
}

void main() {
  group('EmailConfirmationScreen', () {
    testWidgets('verifica el token_hash y se queda en la confirmación', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(
        _wrap(repository, '/auth/callback?token_hash=tok123&type=signup'),
      );
      await tester.pumpAndSettle();

      expect(repository.verifyCallCount, 1);
      expect(repository.lastTokenHash, 'tok123');
      expect(repository.lastTokenType, 'signup');
      // El token_hash no necesita el canje PKCE.
      expect(repository.exchangeCallCount, 0);

      expect(find.text('¡Cuenta confirmada!'), findsOneWidget);
      // Es una pantalla final: no navega sola a ningún sitio.
      expect(find.text('ONBOARDING'), findsNothing);
    });

    testWidgets('"Entrar" lleva al alta de perfil', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FakeAuthRepository(),
          '/auth/callback?token_hash=tok123&type=signup',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('ONBOARDING'), findsOneWidget);
    });

    testWidgets('con token_hash caducado ofrece pedir un enlace nuevo', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        verifyError: const AuthException('Token has expired'),
      );
      await tester.pumpWidget(
        _wrap(repository, '/auth/callback?token_hash=caducado&type=signup'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Pedir un enlace nuevo'),
      );
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('canjea el código PKCE si el enlace trae `code`', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repository, '/auth/callback?code=abc123'));
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 1);
      expect(find.text('¡Cuenta confirmada!'), findsOneWidget);
    });

    testWidgets('muestra el error si el canje falla', (tester) async {
      final repository = FakeAuthRepository(
        exchangeError: const AuthException('bad code'),
      );
      await tester.pumpWidget(_wrap(repository, '/auth/callback?code=abc123'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);
    });

    testWidgets('con `error_description` avisa sin intentar confirmar', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(
        _wrap(repository, '/auth/callback?error_description=link+expired'),
      );
      await tester.pumpAndSettle();

      expect(repository.verifyCallCount, 0);
      expect(repository.exchangeCallCount, 0);
      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);
    });
  });
}
