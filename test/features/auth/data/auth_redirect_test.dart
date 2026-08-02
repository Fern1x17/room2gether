import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/auth/data/auth_redirect.dart';

void main() {
  group('parseAuthCallbackParams', () {
    test('lee el code del query, antes del fragmento', () {
      // Forma real de la vuelta de Supabase: GoTrue parsea el redirect_to
      // ".../#/auth/callback" y escribe el code en el query string, que va
      // antes del fragmento.
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/?code=abc123#/auth/callback'),
      );

      expect(params.code, 'abc123');
      expect(params.errorDescription, isNull);
      expect(params.isNotEmpty, isTrue);
    });

    test('lee el code cuando no hay fragmento (vuelta al Site URL)', () {
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/?code=abc123'),
      );

      expect(params.code, 'abc123');
    });

    test('lee el code cuando viaja dentro del fragmento', () {
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/#/auth/callback?code=abc123'),
      );

      expect(params.code, 'abc123');
    });

    test('lee el token_hash y el type de la plantilla del proyecto', () {
      // Forma que genera la plantilla "Confirm signup" configurada en Supabase.
      final params = parseAuthCallbackParams(
        Uri.parse(
          'https://room2gether.com/#/auth/callback'
          '?token_hash=pkce_abc123&type=signup',
        ),
      );

      expect(params.tokenHash, 'pkce_abc123');
      expect(params.type, 'signup');
      expect(params.code, isNull);
      expect(params.isNotEmpty, isTrue);
    });

    test('lee el error cuando el fragmento entero son los parámetros', () {
      final params = parseAuthCallbackParams(
        Uri.parse(
          'https://room2gether.com/#error=access_denied&error_code=otp_expired'
          '&error_description=Email+link+is+invalid+or+has+expired',
        ),
      );

      expect(params.code, isNull);
      expect(params.errorDescription, 'Email link is invalid or has expired');
    });

    test('cae al parámetro error si no hay error_description', () {
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/?error=access_denied'),
      );

      expect(params.errorDescription, 'access_denied');
    });

    test('una URL normal no trae parámetros de callback', () {
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/#/feed'),
      );

      expect(params.isEmpty, isTrue);
    });

    test('un code vacío cuenta como ausente', () {
      final params = parseAuthCallbackParams(
        Uri.parse('https://room2gether.com/?code='),
      );

      expect(params.isEmpty, isTrue);
    });
  });
}
