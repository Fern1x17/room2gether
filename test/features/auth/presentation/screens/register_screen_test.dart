import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/auth/presentation/screens/register_screen.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap([FakeAuthRepository? repository]) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        repository ?? FakeAuthRepository(),
      ),
    ],
    child: const MaterialApp(home: RegisterScreen()),
  );
}

/// El formulario no cabe entero en el alto del test (800x600): hay que
/// acercar el widget antes de pulsarlo o el toque cae fuera de pantalla.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Rellena el formulario con datos válidos (mayor de edad) y lo envía.
Future<void> _submitValidForm(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Ana');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'nuevo@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    'password123',
  );

  // El selector se abre con "hoy menos 18 años", que ya es una fecha válida.
  await _tap(tester, find.widgetWithText(TextFormField, 'Fecha de nacimiento'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await _tap(tester, find.byType(Checkbox));
  await tester.pump();

  await _tap(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
  await tester.pump(); // arranca el signUp
  await tester.pump(); // completa el Future
}

void main() {
  group('RegisterScreen', () {
    testWidgets('muestra errores de validación al enviar el formulario vacío', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await _tap(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

      expect(find.text('Introduce un nombre.'), findsOneWidget);
      expect(find.text('Introduce tu email.'), findsOneWidget);
      expect(find.text('Introduce una contraseña.'), findsOneWidget);
      expect(find.text('Introduce tu fecha de nacimiento.'), findsOneWidget);
      expect(
        find.text('Debes aceptar la política de privacidad para continuar.'),
        findsOneWidget,
      );
    });

    testWidgets('el campo de fecha de nacimiento abre el selector de fecha', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(
        find.widgetWithText(TextFormField, 'Fecha de nacimiento'),
      );
      await tester.pumpAndSettle();

      // El diálogo del selector usa el helpText que le pasamos.
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('Fecha de nacimiento'), findsWidgets);
    });

    testWidgets('bloquea el envío si no se acepta la política de privacidad', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await _tap(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

      expect(
        find.text('Debes aceptar la política de privacidad para continuar.'),
        findsOneWidget,
      );
    });

    testWidgets('el nombre es obligatorio y viaja al registro', (tester) async {
      final repository = FakeAuthRepository(signUpWithoutSession: true);
      await tester.pumpWidget(_wrap(repository));

      await _submitValidForm(tester);

      expect(repository.lastDisplayName, 'Ana');
    });

    testWidgets(
      'si falta confirmar el email cambia el formulario por el aviso, sin '
      'cambiar de pantalla',
      (tester) async {
        await tester.pumpWidget(
          _wrap(FakeAuthRepository(signUpWithoutSession: true)),
        );

        await _submitValidForm(tester);

        expect(
          find.text('Revisa tu correo y confirma tu cuenta.'),
          findsOneWidget,
        );
        expect(find.textContaining('nuevo@example.com'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Reenviar correo'),
          findsOneWidget,
        );
        // El formulario ya no está, pero seguimos en la pantalla de registro.
        expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsNothing);
        expect(find.byType(RegisterScreen), findsOneWidget);
      },
    );

    testWidgets('"Cambiar el email" devuelve al formulario con lo escrito', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FakeAuthRepository(signUpWithoutSession: true)),
      );

      await _submitValidForm(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Cambiar el email'));
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsOneWidget);
      // Los controladores siguen vivos: no hay que reescribir nada.
      expect(find.text('nuevo@example.com'), findsOneWidget);
    });
  });
}
