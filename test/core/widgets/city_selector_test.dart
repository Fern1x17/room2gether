import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/cities/city.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/widgets/city_selector.dart';

import '../cities/fake_cities.dart';
import '../places/fake_places.dart';

void main() {
  group('CitySelector', () {
    late City? selected;
    late FakeCitiesRepository repository;
    late FakePlacesService places;

    Widget wrap({FakePlacesService? placesService}) {
      selected = null;
      repository = FakeCitiesRepository(cities: seedCities);
      places = placesService ?? FakePlacesService();
      return ProviderScope(
        overrides: [
          citiesRepositoryProvider.overrideWithValue(repository),
          placesServiceProvider.overrideWithValue(places),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CitySelector(onCitySelected: (city) => selected = city),
          ),
        ),
      );
    }

    /// Escribe en el campo y deja pasar el debounce del selector.
    Future<void> typeAndWait(WidgetTester tester, String text) async {
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), text);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'al escribir muestra sugerencias de Places y al elegir emite la ciudad '
      'del catálogo',
      (tester) async {
        await tester.pumpWidget(wrap());
        await typeAndWait(tester, 'coru');

        expect(find.text('A Coruña'), findsOneWidget);
        expect(find.text('A Coruña, España'), findsOneWidget);

        await tester.tap(find.text('A Coruña'));
        // Deja pasar también el debounce que dispara el texto autocompletado.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(selected?.id, 'city-coruna');
        expect(repository.lastPlaceId, 'place-coruna');
        expect(places.sessionsEnded, 1);
      },
    );

    testWidgets('una ciudad nueva se registra en el catálogo al elegirla', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await typeAndWait(tester, 'madri');

      await tester.tap(find.text('Madrid, España'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(selected?.id, 'city-madrid');
      expect(repository.cities.any((city) => city.name == 'Madrid'), isTrue);
    });

    testWidgets('el texto libre no emite ninguna ciudad', (tester) async {
      await tester.pumpWidget(wrap());
      await typeAndWait(tester, 'Marte');

      expect(selected, isNull);
    });

    testWidgets('si Places falla se muestra el error de sugerencias', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(placesService: FakePlacesService(error: Exception('sin red'))),
      );
      await typeAndWait(tester, 'coru');

      expect(
        find.text('No se pudieron cargar las sugerencias.'),
        findsOneWidget,
      );
    });
  });
}
