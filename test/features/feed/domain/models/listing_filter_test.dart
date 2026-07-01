import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/feed/domain/models/listing_filter.dart';

void main() {
  group('ListingFilter', () {
    test('isEmpty es true cuando no hay ningún criterio', () {
      expect(const ListingFilter().isEmpty, isTrue);
    });

    test('isEmpty es false si hay algún criterio', () {
      expect(const ListingFilter(city: 'Valencia').isEmpty, isFalse);
    });

    test('dos filtros con los mismos valores son iguales', () {
      const a = ListingFilter(city: 'Valencia', maxPrice: 500);
      const b = ListingFilter(city: 'Valencia', maxPrice: 500);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toJson/fromJson hacen un roundtrip fiel', () {
      const original = ListingFilter(
        city: 'Madrid',
        neighborhood: 'Chamberí',
        maxPrice: 600,
        type: 'seeking',
      );
      final roundTripped = ListingFilter.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });
  });
}
