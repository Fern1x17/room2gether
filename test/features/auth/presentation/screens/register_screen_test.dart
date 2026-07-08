import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/auth/presentation/screens/register_screen.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
    child: const MaterialApp(home: RegisterScreen()),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('muestra errores de validación al enviar el formulario vacío', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

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

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

      expect(
        find.text('Debes aceptar la política de privacidad para continuar.'),
        findsOneWidget,
      );
    });
  });
}
