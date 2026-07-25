import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/screens/auth_callback_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

/// Router mínimo con la ruta de callback y destinos de éxito/error, para
/// comprobar a dónde navega la pantalla sin arrancar toda la app.
GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackScreen(
          code: state.uri.queryParameters['code'],
          errorDescription: state.uri.queryParameters['error_description'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const Scaffold(body: Text('ONBOARDING')),
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
  group('AuthCallbackScreen', () {
    testWidgets('canjea el código y redirige a onboarding', (tester) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repository, '/auth/callback?code=abc123'));
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 1);
      expect(find.text('ONBOARDING'), findsOneWidget);
    });

    testWidgets('muestra error y ofrece ir a login si el canje falla', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        exchangeError: const AuthException('bad code'),
      );
      await tester.pumpWidget(_wrap(repository, '/auth/callback?code=abc123'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Ir a iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('sin código muestra error sin intentar el canje', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repository, '/auth/callback'));
      await tester.pumpAndSettle();

      expect(repository.exchangeCallCount, 0);
      expect(find.textContaining('No hemos podido confirmar'), findsOneWidget);
    });
  });
}
