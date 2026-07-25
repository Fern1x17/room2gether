import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/moderation/domain/models/blocked_user.dart';
import 'package:room2gether/features/moderation/presentation/screens/blocked_users_screen.dart';

import '../../fakes/fake_moderation_repository.dart';

Widget _wrap(FakeModerationRepository fakeRepo) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      moderationRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: const MaterialApp(home: BlockedUsersScreen()),
  );
}

BlockedUser _blocked(String id, String name) =>
    BlockedUser(id: id, displayName: name, blockedAt: DateTime(2026, 7, 20));

void main() {
  group('BlockedUsersScreen', () {
    testWidgets('muestra el vacío cuando no hay bloqueados', (tester) async {
      await tester.pumpWidget(_wrap(FakeModerationRepository()));
      await tester.pumpAndSettle();

      expect(find.text('No has bloqueado a nadie.'), findsOneWidget);
    });

    testWidgets('lista los bloqueados con su fecha', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FakeModerationRepository(blockedUsers: [_blocked('user-2', 'Ana')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bloqueado el 20 de julio de 2026'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Desbloquear'),
        findsOneWidget,
      );
    });

    testWidgets('desbloquear pide confirmación y llama al repositorio', (
      tester,
    ) async {
      final fakeRepo = FakeModerationRepository(
        blockedIds: {'user-2'},
        blockedUsers: [_blocked('user-2', 'Ana')],
      );
      await tester.pumpWidget(_wrap(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Desbloquear'));
      await tester.pumpAndSettle();

      // Diálogo de confirmación.
      expect(find.text('Desbloquear usuario'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
      await tester.pumpAndSettle();

      expect(fakeRepo.unblockedIds, ['user-2']);
      expect(find.text('Ana desbloqueado.'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no desbloquea', (tester) async {
      final fakeRepo = FakeModerationRepository(
        blockedIds: {'user-2'},
        blockedUsers: [_blocked('user-2', 'Ana')],
      );
      await tester.pumpWidget(_wrap(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Desbloquear'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(fakeRepo.unblockedIds, isEmpty);
    });
  });
}
