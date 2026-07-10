import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/widgets/address_selector.dart';

import '../places/fake_places.dart';

void main() {
  group('AddressSelector', () {
    late AddressSelection? selected;
    late bool cleared;
    late FakePlacesService places;

    Widget wrap({FakePlacesService? placesService, bool neighborhoodsOnly = false}) {
      selected = null;
      cleared = false;
      places = placesService ?? FakePlacesService();
      return ProviderScope(
        overrides: [placesServiceProvider.overrideWithValue(places)],
        child: MaterialApp(
          home: Scaffold(
            body: AddressSelector(
              cityName: 'A Coruña',
              neighborhoodsOnly: neighborhoodsOnly,
              onSelected: (selection) {
                selected = selection;
                if (selection == null) cleared = true;
              },
            ),
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
      'al elegir una dirección pide los detalles y emite la selección con '
      'su barrio derivado',
      (tester) async {
        await tester.pumpWidget(wrap());
        await typeAndWait(tester, 'rúa real');

        expect(find.text('Rúa Real, 12'), findsOneWidget);

        await tester.tap(find.text('Rúa Real, 12, A Coruña, España'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(places.detailsFetched, ['place-rua-real-12']);
        expect(selected?.isPreciseAddress, isTrue);
        expect(
          selected?.formattedAddress,
          'Rúa Real 12, 15003 A Coruña, España',
        );
        expect(selected?.neighborhood, 'Cidade Vella');
        expect(selected?.latitude, isNotNull);
      },
    );

    testWidgets(
      'en modo barrio emite el nombre sin pedir detalles (sin coste extra)',
      (tester) async {
        await tester.pumpWidget(wrap(neighborhoodsOnly: true));
        await typeAndWait(tester, 'castros');

        await tester.tap(find.text('Os Castros, A Coruña, España'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(places.detailsFetched, isEmpty);
        expect(places.sessionsEnded, 1);
        expect(selected?.isPreciseAddress, isFalse);
        expect(selected?.neighborhood, 'Os Castros');
      },
    );

    testWidgets('el texto libre no emite ninguna selección', (tester) async {
      await tester.pumpWidget(wrap());
      await typeAndWait(tester, 'sitio inventado');

      expect(selected, isNull);
      expect(cleared, isFalse);
    });

    testWidgets('si Places falla se muestra el error de sugerencias', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(placesService: FakePlacesService(error: Exception('sin red'))),
      );
      await typeAndWait(tester, 'castros');

      expect(
        find.text('No se pudieron cargar las sugerencias.'),
        findsOneWidget,
      );
    });
  });
}
