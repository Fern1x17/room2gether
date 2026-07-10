import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('validateEmail', () {
    test('rechaza email vacío', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rechaza email sin arroba', () {
      expect(validateEmail('no-es-un-email'), isNotNull);
    });

    test('rechaza email sin dominio', () {
      expect(validateEmail('usuario@'), isNotNull);
    });

    test('acepta un email válido', () {
      expect(validateEmail('usuario@ejemplo.com'), isNull);
    });
  });

  group('validatePassword', () {
    test('rechaza contraseña vacía', () {
      expect(validatePassword(''), isNotNull);
    });

    test('rechaza contraseña corta', () {
      expect(validatePassword('1234567'), isNotNull);
    });

    test('acepta contraseña con longitud mínima', () {
      expect(validatePassword('12345678'), isNull);
    });
  });

  group('validateBirthdate', () {
    // Fecha de referencia fija para que los tests no dependan del día real.
    final now = DateTime(2026, 7, 2);

    test('rechaza fecha no seleccionada', () {
      expect(validateBirthdate(null, now: now), isNotNull);
    });

    test('rechaza menor de edad', () {
      expect(validateBirthdate(DateTime(2010, 1, 1), now: now), isNotNull);
    });

    test('acepta cumplir 18 exactamente hoy', () {
      expect(validateBirthdate(DateTime(2008, 7, 2), now: now), isNull);
    });

    test('rechaza a quien cumple 18 mañana', () {
      expect(validateBirthdate(DateTime(2008, 7, 3), now: now), isNotNull);
    });

    test('rechaza una fecha fuera de rango razonable', () {
      expect(validateBirthdate(DateTime(1900, 1, 1), now: now), isNotNull);
    });

    test('acepta una fecha adulta normal', () {
      expect(validateBirthdate(DateTime(2000, 5, 10), now: now), isNull);
    });
  });

  group('ageInYears', () {
    test('resta un año si el cumpleaños de este año no ha llegado', () {
      expect(ageInYears(DateTime(2000, 12, 31), DateTime(2026, 7, 2)), 25);
    });

    test('cuenta el año completo si el cumpleaños ya pasó', () {
      expect(ageInYears(DateTime(2000, 7, 2), DateTime(2026, 7, 2)), 26);
    });
  });
}
