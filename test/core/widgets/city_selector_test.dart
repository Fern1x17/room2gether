import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/core/cities/cities_repository.dart';
import 'package:roomie/core/cities/city.dart';
import 'package:roomie/core/widgets/city_selector.dart';

import '../cities/fake_cities.dart';

void main() {
  group('CitySelector', () {
    late City? selected;

    Widget wrap() {
      selected = null;
      return ProviderScope(
        overrides: [
          citiesRepositoryProvider.overrideWithValue(
            FakeCitiesRepository(cities: seedCities),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CitySelector(onCitySelected: (city) => selected = city),
          ),
        ),
      );
    }

    testWidgets('al escribir muestra sugerencias y al elegir emite la ciudad', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'coru');
      await tester.pumpAndSettle();

      expect(find.text('A Coruña'), findsOneWidget);

      await tester.tap(find.text('A Coruña'));
      await tester.pumpAndSettle();

      expect(selected?.id, 'city-coruna');
    });

    testWidgets(
      'con el campo vacío muestra directamente las ciudades activas',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextFormField));
        await tester.pumpAndSettle();

        expect(find.text('Vigo'), findsOneWidget);
        expect(find.text('Santiago de Compostela'), findsOneWidget);
      },
    );

    testWidgets('el texto libre no emite ninguna ciudad', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Marte');
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
