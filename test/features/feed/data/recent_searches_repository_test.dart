import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/feed/data/recent_searches_repository.dart';
import 'package:roomie/features/feed/domain/models/listing_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesRecentSearchesRepository', () {
    test('load() empieza vacío', () async {
      final repo = SharedPreferencesRecentSearchesRepository();
      expect(await repo.load(), isEmpty);
    });

    test('save() persiste y lo más reciente queda primero', () async {
      final repo = SharedPreferencesRecentSearchesRepository();
      await repo.save(
        const ListingFilter(cityId: 'city-vigo', cityName: 'Vigo'),
      );
      await repo.save(
        const ListingFilter(cityId: 'city-coruna', cityName: 'A Coruña'),
      );

      final saved = await repo.load();
      expect(saved.map((f) => f.cityId), ['city-coruna', 'city-vigo']);
      // El nombre viaja en el JSON para poder pintar el chip.
      expect(saved.first.cityName, 'A Coruña');
    });

    test(
      'save() de un filtro repetido lo mueve al principio sin duplicar',
      () async {
        final repo = SharedPreferencesRecentSearchesRepository();
        await repo.save(const ListingFilter(cityId: 'city-vigo'));
        await repo.save(const ListingFilter(cityId: 'city-coruna'));
        await repo.save(const ListingFilter(cityId: 'city-vigo'));

        final saved = await repo.load();
        expect(saved.map((f) => f.cityId), ['city-vigo', 'city-coruna']);
      },
    );

    test('save() de un filtro vacío no guarda nada', () async {
      final repo = SharedPreferencesRecentSearchesRepository();
      await repo.save(const ListingFilter());

      expect(await repo.load(), isEmpty);
    });
  });
}
