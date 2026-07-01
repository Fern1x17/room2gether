import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/auth/domain/validators/auth_validators.dart';

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

  group('validateAge', () {
    test('rechaza edad vacía', () {
      expect(validateAge(''), isNotNull);
    });

    test('rechaza texto no numérico', () {
      expect(validateAge('abc'), isNotNull);
    });

    test('rechaza menor de edad', () {
      expect(validateAge('17'), isNotNull);
    });

    test('acepta exactamente 18 años', () {
      expect(validateAge('18'), isNull);
    });

    test('rechaza una edad fuera de rango razonable', () {
      expect(validateAge('150'), isNotNull);
    });

    test('acepta una edad adulta normal', () {
      expect(validateAge('25'), isNull);
    });
  });
}
