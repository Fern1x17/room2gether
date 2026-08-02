import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap({FakeAuthRepository? repository, bool emailNotConfirmed = false}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        repository ?? FakeAuthRepository(),
      ),
    ],
    child: MaterialApp(home: LoginScreen(emailNotConfirmed: emailNotConfirmed)),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('muestra errores de validación al enviar el formulario vacío', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();

      expect(find.text('Introduce tu email.'), findsOneWidget);
      expect(find.text('Introduce una contraseña.'), findsOneWidget);
    });

    testWidgets('rechaza un email con formato inválido', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'no-es-un-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();

      expect(find.text('Introduce un email válido.'), findsOneWidget);
    });

    testWidgets('sin aviso previo no muestra el bloque de reenvío', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('Tu cuenta está sin confirmar'), findsNothing);
    });

    testWidgets(
      'llegando desde un enlace caducado ofrece reenviar la confirmación',
      (tester) async {
        final repository = FakeAuthRepository();
        await tester.pumpWidget(
          _wrap(repository: repository, emailNotConfirmed: true),
        );

        expect(
          find.textContaining('Tu cuenta está sin confirmar'),
          findsOneWidget,
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'nuevo@example.com',
        );
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Reenviar confirmación'),
        );
        await tester.pump();
        await tester.pump();

        expect(repository.resendCallCount, 1);
        expect(
          find.text('Te hemos reenviado el correo de confirmación.'),
          findsOneWidget,
        );
        // Cooldown activo: el botón queda deshabilitado con cuenta atrás.
        expect(find.textContaining('Reenviar confirmación ('), findsOneWidget);
      },
    );

    testWidgets('sin email escrito no llama al reenvío y lo explica', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(
        _wrap(repository: repository, emailNotConfirmed: true),
      );

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Reenviar confirmación'),
      );
      await tester.pump();

      expect(repository.resendCallCount, 0);
      expect(
        find.text('Escribe tu email para reenviarte la confirmación.'),
        findsOneWidget,
      );
    });

    testWidgets('un login con la cuenta sin confirmar revela el reenvío', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        signInError: const AuthException(
          'Email not confirmed',
          code: 'email_not_confirmed',
        ),
      );
      await tester.pumpWidget(_wrap(repository: repository));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nuevo@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('Tu cuenta está sin confirmar'),
        findsOneWidget,
      );
    });
  });
}
