import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/listing/domain/listing_policy.dart';
import 'package:roomie/features/listing/domain/validators/listing_validators.dart';

void main() {
  group('canCreateListing (regla: una publicación activa por usuario)', () {
    test('permite crear sin publicaciones activas', () {
      expect(canCreateListing(activeListingsCount: 0), isTrue);
    });

    test('bloquea con una publicación activa', () {
      expect(canCreateListing(activeListingsCount: 1), isFalse);
    });
  });

  group('validadores de publicación', () {
    test('título obligatorio', () {
      expect(validateListingTitle(''), isNotNull);
      expect(validateListingTitle('Habitación centro'), isNull);
    });

    test('ciudad obligatoria', () {
      expect(validateListingCity(''), isNotNull);
      expect(validateListingCity('Valencia'), isNull);
    });

    test('barrio obligatorio solo si ofrece piso', () {
      expect(validateListingNeighborhood('', isOffering: true), isNotNull);
      expect(validateListingNeighborhood('', isOffering: false), isNull);
      expect(validateListingNeighborhood('Ruzafa', isOffering: true), isNull);
    });

    test('precio: obligatorio, numérico y no negativo', () {
      expect(validateListingPrice(''), isNotNull);
      expect(validateListingPrice('abc'), isNotNull);
      expect(validateListingPrice('-5'), isNotNull);
      expect(validateListingPrice('400'), isNull);
    });

    test('rango de presupuesto: ambos obligatorios y min <= max', () {
      expect(validateListingBudgetRange('', '500'), isNotNull);
      expect(validateListingBudgetRange('600', '500'), isNotNull);
      expect(validateListingBudgetRange('300', '500'), isNull);
      expect(validateListingBudgetRange('500', '500'), isNull);
    });

    test('fotos obligatorias solo si ofrece piso', () {
      expect(validateListingPhotos(0, isOffering: true), isNotNull);
      expect(validateListingPhotos(0, isOffering: false), isNull);
      expect(validateListingPhotos(2, isOffering: true), isNull);
    });
  });
}
