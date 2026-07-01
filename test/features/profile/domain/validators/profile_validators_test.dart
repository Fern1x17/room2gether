import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/profile/domain/validators/profile_validators.dart';

void main() {
  group('validateDisplayName', () {
    test('rechaza nombre vacío', () {
      expect(validateDisplayName(''), isNotNull);
    });

    test('rechaza solo espacios', () {
      expect(validateDisplayName('   '), isNotNull);
    });

    test('acepta un nombre válido', () {
      expect(validateDisplayName('Fernando'), isNull);
    });
  });

  group('validateBudgetRange', () {
    test('acepta ambos vacíos (presupuesto opcional)', () {
      expect(validateBudgetRange('', ''), isNull);
    });

    test('rechaza mínimo mayor que máximo', () {
      expect(validateBudgetRange('800', '500'), isNotNull);
    });

    test('acepta un rango válido', () {
      expect(validateBudgetRange('400', '800'), isNull);
    });

    test('acepta mínimo igual a máximo', () {
      expect(validateBudgetRange('500', '500'), isNull);
    });

    test('rechaza texto no numérico', () {
      expect(validateBudgetRange('abc', '500'), isNotNull);
    });
  });

  group('validateCleanlinessLevel', () {
    test('acepta null (opcional)', () {
      expect(validateCleanlinessLevel(null), isNull);
    });

    test('rechaza fuera de rango', () {
      expect(validateCleanlinessLevel(0), isNotNull);
      expect(validateCleanlinessLevel(6), isNotNull);
    });

    test('acepta dentro de rango', () {
      expect(validateCleanlinessLevel(1), isNull);
      expect(validateCleanlinessLevel(5), isNull);
    });
  });
}
