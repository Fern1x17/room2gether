import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/data/auth_repository.dart';
import 'package:roomie/features/profile/data/profile_repository.dart';
import 'package:roomie/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

Widget _wrap({FakeProfileRepository? profileRepository}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(
        profileRepository ?? FakeProfileRepository(profile: fakeProfile(displayName: 'Ana')),
      ),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
    child: const MaterialApp(home: EditProfileScreen()),
  );
}

void main() {
  group('EditProfileScreen', () {
    testWidgets('muestra los datos del perfil cargado', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('muestra error si el nombre queda vacío', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), '');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Introduce un nombre.'), findsOneWidget);
    });

    testWidgets('muestra error si el presupuesto mínimo es mayor que el máximo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Presupuesto mín. (€)'),
        '800',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Presupuesto máx. (€)'),
        '500',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
      await tester.pumpAndSettle();

      expect(
        find.text('El presupuesto mínimo no puede ser mayor que el máximo.'),
        findsOneWidget,
      );
    });
  });
}
