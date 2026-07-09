import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/feed/domain/models/listing_filter.dart';

void main() {
  group('ListingFilter', () {
    test('isEmpty es true cuando no hay ningún criterio', () {
      expect(const ListingFilter().isEmpty, isTrue);
    });

    test('isEmpty es false si hay algún criterio', () {
      expect(const ListingFilter(cityId: 'city-vigo').isEmpty, isFalse);
    });

    test('dos filtros con los mismos criterios son iguales', () {
      const a = ListingFilter(cityId: 'city-vigo', maxPrice: 500);
      const b = ListingFilter(cityId: 'city-vigo', maxPrice: 500);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('cityName no afecta a la igualdad (es solo presentación)', () {
      const a = ListingFilter(cityId: 'city-vigo', cityName: 'Vigo');
      const b = ListingFilter(cityId: 'city-vigo');
      expect(a, equals(b));
    });

    test('toJson/fromJson hacen un roundtrip fiel', () {
      const original = ListingFilter(
        cityId: 'city-coruna',
        cityName: 'A Coruña',
        neighborhood: 'Monte Alto',
        maxPrice: 600,
        type: 'seeking',
      );
      final roundTripped = ListingFilter.fromJson(original.toJson());
      expect(roundTripped, equals(original));
      expect(roundTripped.cityName, 'A Coruña');
    });

    test('las búsquedas antiguas con city como texto se leen sin ciudad', () {
      final legacy = ListingFilter.fromJson(const {
        'city': 'Valencia',
        'maxPrice': 500,
      });
      expect(legacy.cityId, isNull);
      expect(legacy.maxPrice, 500);
    });
  });
}
