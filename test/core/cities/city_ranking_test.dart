import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/core/cities/city_ranking.dart';
import 'package:roomie/core/utils/normalize_text.dart';

import 'fake_cities.dart';

void main() {
  group('normalizeText', () {
    test('minúsculas y sin tildes ni eñes', () {
      expect(normalizeText('A Coruña'), 'a coruna');
      expect(normalizeText('  VIGO  '), 'vigo');
      expect(normalizeText('Santiagó'), 'santiago');
    });
  });

  group('cityMatchLevel (niveles de la especificación)', () {
    final coruna = seedCities[2];
    final santiago = seedCities[1];

    test('nivel 0: coincidencia exacta con normalized_name', () {
      expect(cityMatchLevel(coruna, 'a coruna'), 0);
    });

    test('nivel 1: normalized_name empieza por lo escrito', () {
      expect(cityMatchLevel(coruna, 'a cor'), 1);
    });

    test('nivel 2: alguna palabra empieza por lo escrito', () {
      expect(cityMatchLevel(santiago, 'comp'), 2);
      expect(cityMatchLevel(coruna, 'coru'), 2);
    });

    test('nivel 3: normalized_name contiene lo escrito', () {
      expect(cityMatchLevel(santiago, 'ntiago'), 3);
    });

    test('nivel 4: algún alias contiene lo escrito', () {
      expect(cityMatchLevel(coruna, 'la cor'), 4);
    });

    test('sin coincidencia devuelve null', () {
      expect(cityMatchLevel(santiago, 'madrid'), isNull);
    });
  });

  group('rankCities', () {
    test('ordena por nivel de coincidencia', () {
      // 'coru' → A Coruña nivel 2 (palabra "coruna" empieza por ello); ningún
      // otro coincide.
      final results = rankCities(seedCities, 'coru');
      expect(results.map((c) => c.name), ['A Coruña']);
    });

    test('compara con el texto normalizado (tildes fuera)', () {
      final results = rankCities(seedCities, 'Coruña');
      expect(results.single.name, 'A Coruña');
    });

    test('con consulta vacía devuelve las ciudades recibidas', () {
      final results = rankCities(seedCities, '   ');
      expect(results, hasLength(seedCities.length));
    });

    test('un alias encuentra la ciudad (la coruna)', () {
      final results = rankCities(seedCities, 'la corun');
      expect(results.single.name, 'A Coruña');
    });

    test('máximo 8 resultados', () {
      final many = [
        for (var i = 0; i < 12; i++)
          fakeCity(id: 'c$i', name: 'Vigo $i', normalizedName: 'vigo $i'),
      ];
      final results = rankCities(many, 'vigo');
      expect(results, hasLength(8));
    });

    test('el nivel manda: exacta antes que empieza-por', () {
      final cities = [
        fakeCity(
          id: 'c1',
          name: 'Vigo del Norte',
          normalizedName: 'vigo del norte',
        ),
        fakeCity(id: 'c2', name: 'Vigo', normalizedName: 'vigo'),
      ];
      final results = rankCities(cities, 'vigo');
      expect(results.first.id, 'c2');
    });
  });
}
