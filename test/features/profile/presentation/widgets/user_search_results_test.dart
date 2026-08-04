import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/profile/data/user_search_repository.dart';
import 'package:room2gether/features/profile/presentation/controllers/user_search_controller.dart';
import 'package:room2gether/features/profile/presentation/widgets/user_search_results.dart';

import '../../fakes/fake_user_search_repository.dart';

/// Monta la lista y escribe una búsqueda, para que el controlador tenga
/// resultados que pintar.
Future<void> _search(
  WidgetTester tester,
  FakeUserSearchRepository repo, {
  String query = 'ana',
}) async {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      userSearchRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: UserSearchResults(onUserTap: (_) {}),
        ),
      ),
    ),
  );
  // Sin `await`: el debounce de la búsqueda es un `Future.delayed`, y con el
  // reloj falso del tester solo avanza haciendo `pump`. Esperarlo aquí
  // bloquearía el test para siempre.
  unawaited(
    container.read(userSearchControllerProvider.notifier).updateQuery(query),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  group('UserSearchResults', () {
    testWidgets('un usuario normal enseña su ciudad', (tester) async {
      await _search(
        tester,
        FakeUserSearchRepository(
          pages: [
            [fakeUserSearchResult(displayName: 'Ana', cityName: 'Vigo')],
          ],
        ),
      );

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Vigo'), findsOneWidget);
      expect(find.text('Bloqueado'), findsNothing);
    });

    // Los bloqueados por mí salen a propósito: es la vía para entrar en su
    // perfil y deshacerlo sin ir a buscar la lista de ajustes.
    testWidgets('un bloqueado sale marcado y sin su ciudad', (tester) async {
      await _search(
        tester,
        FakeUserSearchRepository(
          pages: [
            [
              fakeUserSearchResult(
                displayName: 'Ana',
                cityName: 'Vigo',
                isBlocked: true,
              ),
            ],
          ],
        ),
      );

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bloqueado'), findsOneWidget);
      expect(find.text('Vigo'), findsNothing);
    });
  });
}
