import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/profile/data/user_search_repository.dart';
import 'package:room2gether/features/profile/domain/models/user_search_result.dart';
import 'package:room2gether/features/profile/presentation/controllers/user_search_controller.dart';

import '../../fakes/fake_user_search_repository.dart';

/// Una página llena, que es lo que hace creer al controlador que hay más.
List<UserSearchResult> fullPage({String prefix = 'a'}) => [
  for (var i = 0; i < kUserSearchPageSize; i++)
    fakeUserSearchResult(id: '$prefix-$i', displayName: 'Usuario $prefix$i'),
];

ProviderContainer containerWith(FakeUserSearchRepository repo) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      userSearchRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  // Mantiene vivo el provider autoDispose durante todo el test.
  container.listen(userSearchControllerProvider, (_, _) {});
  return container;
}

void main() {
  group('UserSearchController', () {
    test('no consulta con menos del mínimo de caracteres', () async {
      final repo = FakeUserSearchRepository();
      final container = containerWith(repo);

      await container
          .read(userSearchControllerProvider.notifier)
          .updateQuery('n');

      expect(repo.calls, isEmpty);
      final state = container.read(userSearchControllerProvider);
      expect(state.isQueryTooShort, isTrue);
      expect(state.results, isEmpty);
    });

    test('busca y expone los resultados', () async {
      final repo = FakeUserSearchRepository(
        pages: [
          [fakeUserSearchResult(displayName: 'Núria', cityName: 'A Coruña')],
        ],
      );
      final container = containerWith(repo);

      await container
          .read(userSearchControllerProvider.notifier)
          .updateQuery('  nur  ');

      // El texto llega a la RPC ya sin espacios sobrantes.
      expect(repo.calls.single.query, 'nur');
      expect(repo.calls.single.limit, kUserSearchPageSize);
      expect(repo.calls.single.offset, 0);

      final state = container.read(userSearchControllerProvider);
      expect(state.results.single.displayName, 'Núria');
      expect(state.isSearching, isFalse);
      // Una página a medias significa que no hay más.
      expect(state.hasMore, isFalse);
    });

    test('el debounce descarta las pulsaciones intermedias', () async {
      final repo = FakeUserSearchRepository(pages: [[fakeUserSearchResult()]]);
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      // Tres pulsaciones seguidas sin esperar entre ellas.
      unawaited(controller.updateQuery('nu'));
      unawaited(controller.updateQuery('nur'));
      await controller.updateQuery('nuri');

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.query, 'nuri');
    });

    test('una respuesta tardía no pisa a la búsqueda más reciente', () async {
      final repo = FakeUserSearchRepository(
        pages: [
          [fakeUserSearchResult(id: 'viejo', displayName: 'Resultado viejo')],
          [fakeUserSearchResult(id: 'nuevo', displayName: 'Resultado nuevo')],
        ],
      );
      // La primera llamada tarda mucho más que la segunda.
      repo.delays[0] = const Duration(milliseconds: 400);
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      final first = controller.updateQuery('ana');
      // Se espera a que pase el debounce de la primera y salga la petición.
      await Future<void>.delayed(kUserSearchDebounce * 2);
      final second = controller.updateQuery('anab');
      await Future.wait([first, second]);

      expect(repo.calls, hasLength(2));
      final state = container.read(userSearchControllerProvider);
      expect(state.query, 'anab');
      expect(state.results.single.id, 'nuevo');
    });

    test('una página llena habilita la siguiente, con su offset', () async {
      final repo = FakeUserSearchRepository(
        pages: [
          fullPage(),
          [fakeUserSearchResult(id: 'extra', displayName: 'Uno más')],
        ],
      );
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      await controller.updateQuery('usuario');
      expect(container.read(userSearchControllerProvider).hasMore, isTrue);

      await controller.loadMore();

      expect(repo.calls.last.offset, kUserSearchPageSize);
      final state = container.read(userSearchControllerProvider);
      expect(state.results, hasLength(kUserSearchPageSize + 1));
      expect(state.results.last.id, 'extra');
      // La segunda página vino a medias: se acabó la paginación.
      expect(state.hasMore, isFalse);
    });

    test('loadMore no hace nada si no hay más páginas', () async {
      final repo = FakeUserSearchRepository(
        pages: [
          [fakeUserSearchResult()],
        ],
      );
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      await controller.updateQuery('nur');
      await controller.loadMore();

      expect(repo.calls, hasLength(1));
    });

    test('un fallo deja mensaje de error y permite reintentar', () async {
      final repo = FakeUserSearchRepository(error: Exception('caída'));
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      await controller.updateQuery('nur');

      var state = container.read(userSearchControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.results, isEmpty);

      await controller.retry();

      // El reintento vuelve a consultar con el mismo texto.
      expect(repo.calls, hasLength(2));
      state = container.read(userSearchControllerProvider);
      expect(state.query, 'nur');
    });

    test('limpiar el campo vuelve al estado inicial', () async {
      final repo = FakeUserSearchRepository(
        pages: [
          [fakeUserSearchResult()],
        ],
      );
      final container = containerWith(repo);
      final controller = container.read(userSearchControllerProvider.notifier);

      await controller.updateQuery('nur');
      expect(container.read(userSearchControllerProvider).results, hasLength(1));

      await controller.updateQuery('');

      final state = container.read(userSearchControllerProvider);
      expect(state.results, isEmpty);
      expect(state.isQueryTooShort, isTrue);
      expect(state.errorMessage, isNull);
    });
  });
}
