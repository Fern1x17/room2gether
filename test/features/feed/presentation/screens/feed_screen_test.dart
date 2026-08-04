import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/feed/data/recent_searches_repository.dart';
import 'package:room2gether/features/feed/presentation/screens/feed_screen.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';

import '../../../../core/cities/fake_cities.dart';
import '../../../../core/places/fake_places.dart';
import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_feed_repository.dart';
import '../../fakes/fake_recent_searches_repository.dart';

List<Override> _overrides(FakeFeedRepository? feedRepository) => [
  currentUserIdProvider.overrideWithValue('user-1'),
  feedRepositoryProvider.overrideWithValue(
    feedRepository ?? FakeFeedRepository(listings: const []),
  ),
  profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
  recentSearchesRepositoryProvider.overrideWithValue(
    FakeRecentSearchesRepository(),
  ),
  moderationRepositoryProvider.overrideWithValue(FakeModerationRepository()),
  citiesRepositoryProvider.overrideWithValue(FakeCitiesRepository()),
  placesServiceProvider.overrideWithValue(FakePlacesService()),
];

Widget _wrap({FakeFeedRepository? feedRepository}) {
  return ProviderScope(
    overrides: _overrides(feedRepository),
    child: const MaterialApp(home: FeedScreen()),
  );
}

/// Igual que [_wrap] pero con router, para lo que navega a otra ruta.
Widget _wrapWithRouter() {
  return ProviderScope(
    overrides: _overrides(null),
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/feed',
        routes: [
          GoRoute(path: '/feed', builder: (_, _) => const FeedScreen()),
          GoRoute(
            path: '/users/search',
            builder: (_, _) =>
                const Scaffold(body: Text('BUSCADOR DE USUARIOS')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('FeedScreen', () {
    testWidgets('muestra el mensaje de vacío si no hay publicaciones', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('No hay publicaciones que coincidan con tu búsqueda.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra las publicaciones cuando las hay', (tester) async {
      await tester.pumpWidget(
        _wrap(
          feedRepository: FakeFeedRepository(
            listings: [fakeListing(title: 'Habitación en el centro')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('el botón hamburguesa abre el panel de filtros', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar publicaciones'), findsOneWidget);
      // El campo de ciudad ahora es el selector con autocompletado (RF-15).
      expect(find.widgetWithText(TextFormField, 'Ciudad'), findsOneWidget);
    });

    testWidgets('la lupa lleva al buscador de usuarios, no a los filtros', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pumpAndSettle();

      final lupa = find.byIcon(Icons.search);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: lupa, matching: find.byType(IconButton)),
            )
            .tooltip,
        'Buscar usuarios',
      );

      await tester.tap(lupa);
      await tester.pumpAndSettle();

      expect(find.text('BUSCADOR DE USUARIOS'), findsOneWidget);
      expect(find.text('Filtrar publicaciones'), findsNothing);
    });

    testWidgets('sin filtros aplicados el botón no lleva badge', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // FakeProfileRepository no trae ciudad, así que el filtro inicial que
      // arma FeedController queda vacío.
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('con filtros aplicados sale el badge, sin número', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Dos criterios: precio máximo y tipo.
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio máximo (€)'),
        '500',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ofrezco'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsOneWidget);
      // Un punto, no un contador: nada de números encima del icono.
      expect(find.text('2'), findsNothing);
    });

    testWidgets('el botón de filtros se aparta al bajar y vuelve al subir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          feedRepository: FakeFeedRepository(
            listings: [
              for (var i = 0; i < 20; i++)
                fakeListing(id: 'l$i', title: 'Publicación $i'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Oculto = sin acción, para que no se pueda pulsar a ciegas.
      FloatingActionButton filtersButton() => tester.widget<FloatingActionButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is FloatingActionButton &&
              widget.tooltip == 'Filtrar publicaciones',
        ),
      );

      expect(filtersButton().onPressed, isNotNull);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(filtersButton().onPressed, isNull);

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(filtersButton().onPressed, isNotNull);
    });
  });
}
