import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/auth/presentation/screens/register_screen.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
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
      expect(find.text('Introduce tu edad.'), findsOneWidget);
      expect(
        find.text('Debes aceptar la política de privacidad para continuar.'),
        findsOneWidget,
      );
    });

    testWidgets('rechaza una edad menor de 18 años', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Edad'), '17');

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

      expect(
        find.text('Debes ser mayor de edad (18 años) para registrarte.'),
        findsOneWidget,
      );
    });

    testWidgets('bloquea el envío si no se acepta la política de privacidad', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Edad'), '25');

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();

      expect(
        find.text('Debes aceptar la política de privacidad para continuar.'),
        findsOneWidget,
      );
    });
  });
}
