import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/auth/presentation/screens/login_screen.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
    child: const MaterialApp(home: LoginScreen()),
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
  });
}
