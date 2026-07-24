import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';

const _base =
    'https://abcdefg.supabase.co/storage/v1/object/public/avatars/user-1';

void main() {
  group('avatarStoragePathFromUrl', () {
    test('extrae la ruta dentro del bucket', () {
      expect(
        avatarStoragePathFromUrl('$_base/1752000000000.jpg', userId: 'user-1'),
        'user-1/1752000000000.jpg',
      );
    });

    test('ignora la query de la URL', () {
      expect(
        avatarStoragePathFromUrl('$_base/foto.jpg?t=123', userId: 'user-1'),
        'user-1/foto.jpg',
      );
    });

    test('devuelve null si la foto es de otro usuario', () {
      expect(
        avatarStoragePathFromUrl('$_base/foto.jpg', userId: 'user-2'),
        isNull,
      );
    });

    test('devuelve null si la URL no es del bucket de avatares', () {
      expect(
        avatarStoragePathFromUrl(
          'https://abcdefg.supabase.co/storage/v1/object/public/'
          'listing-photos/user-1/foto.jpg',
          userId: 'user-1',
        ),
        isNull,
      );
    });

    test('devuelve null si no hay foto anterior', () {
      expect(avatarStoragePathFromUrl(null, userId: 'user-1'), isNull);
    });

    test('devuelve null ante una URL con salto de directorio', () {
      expect(
        avatarStoragePathFromUrl('$_base/../user-2/foto.jpg', userId: 'user-1'),
        isNull,
      );
    });
  });
}
