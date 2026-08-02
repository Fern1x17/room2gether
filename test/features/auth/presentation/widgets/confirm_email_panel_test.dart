import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/widgets/confirm_email_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

/// Router mínimo: el panel vive en una pantalla cualquiera y navega a
/// `/onboarding` cuando el auto-login entra.
GoRouter _router(VoidCallback onEdit) {
  return GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => Scaffold(
          body: ConfirmEmailPanel(
            email: 'nuevo@example.com',
            password: 'password123',
            onEdit: onEdit,
          ),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(body: Text('ONBOARDING')),
      ),
    ],
  );
}

Widget _wrap(FakeAuthRepository repository, {VoidCallback? onEdit}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: _router(onEdit ?? () {})),
  );
}

void main() {
  group('ConfirmEmailPanel', () {
    testWidgets('muestra el estado de espera', (tester) async {
      await tester.pumpWidget(_wrap(FakeAuthRepository()));
      await tester.pump();

      expect(
        find.text('Revisa tu correo y confirma tu cuenta.'),
        findsOneWidget,
      );
      expect(find.text('Esperando confirmación…'), findsOneWidget);
      // El polling arranca a los 4 s; en el primer frame aún no ha entrado.
      expect(find.text('ONBOARDING'), findsNothing);
    });

    testWidgets(
      'hace polling: espera mientras no está confirmado y entra al confirmarse',
      (tester) async {
        // La 1ª llamada a signIn falla con email_not_confirmed; la 2ª ya entra.
        final repository = FakeAuthRepository(signInUnconfirmedTimes: 1);
        await tester.pumpWidget(_wrap(repository));
        await tester.pump();

        // 1ª vuelta del polling (4 s): sigue sin confirmar → seguimos esperando.
        await tester.pump(const Duration(seconds: 4));
        await tester.pump();
        expect(repository.signInCallCount, 1);
        expect(find.text('ONBOARDING'), findsNothing);

        // 2ª vuelta (otros 4 s): ya confirmado → auto-login y navegación.
        await tester.pump(const Duration(seconds: 4));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(repository.signInCallCount, 2);
        expect(find.text('ONBOARDING'), findsOneWidget);
      },
    );

    testWidgets('reenviar correo llama al repo, avisa y aplica cooldown', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repository));
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reenviar correo'));
      await tester.pump(); // marca _resending
      await tester.pump(); // completa el Future de resend

      expect(repository.resendCallCount, 1);
      expect(
        find.text('Te hemos reenviado el correo de confirmación.'),
        findsOneWidget,
      );
      // El botón queda deshabilitado con cuenta atrás.
      expect(find.textContaining('Reenviar correo ('), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('reenviar correo muestra el error traducido si falla', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        resendError: const AuthException(
          'rate limit',
          code: 'over_email_send_rate_limit',
        ),
      );
      await tester.pumpWidget(_wrap(repository));
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reenviar correo'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('demasiados correos'), findsOneWidget);
    });

    testWidgets('"Cambiar el email" avisa al padre', (tester) async {
      var edited = false;
      await tester.pumpWidget(
        _wrap(FakeAuthRepository(), onEdit: () => edited = true),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(TextButton, 'Cambiar el email'));
      await tester.pump();

      expect(edited, isTrue);
    });
  });
}
