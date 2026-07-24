import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:room2gether/core/utils/image_processing.dart';

Uint8List _pngOf({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 107, 91));
  return img.encodePng(image);
}

void main() {
  // normalizeForCrop decodifica con dart:ui, así que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeForCrop', () {
    test('reduce la foto al lado máximo manteniendo la proporción', () async {
      final result = await normalizeForCrop(_pngOf(width: 4000, height: 2000));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, kAvatarNormalizeSides.first);
      expect(decoded.height, kAvatarNormalizeSides.first ~/ 2);
    });

    test('devuelve siempre JPEG, aunque entre un PNG', () async {
      final result = await normalizeForCrop(_pngOf(width: 900, height: 900));

      expect(result!.sublist(0, 2), [0xFF, 0xD8]);
    });

    test('no amplía una foto ya pequeña', () async {
      final result = await normalizeForCrop(_pngOf(width: 200, height: 300));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, 200);
      expect(decoded.height, 300);
    });

    test(
      'si un tamaño falla, reintenta con el siguiente más pequeño',
      () async {
        // El primer lado es imposible (0 px), así que solo puede salir bien
        // gracias al reintento con el segundo.
        final result = await normalizeForCrop(
          _pngOf(width: 1000, height: 1000),
          sides: const [0, 640],
        );

        final decoded = img.decodeImage(result!)!;
        expect(decoded.width, 640);
      },
    );

    test('devuelve null si ningún tamaño funciona', () async {
      expect(await normalizeForCrop(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });

    test('un intento que tarda demasiado no bloquea: se reintenta', () async {
      // Timeout imposible de cumplir: todos los intentos "tardan demasiado",
      // así que la función tiene que rendirse en vez de quedarse colgada.
      final result = await normalizeForCrop(
        _pngOf(width: 800, height: 800),
        timeout: Duration.zero,
      );

      expect(result, isNull);
    });

    test('la escalera baja hasta un tamaño usable para el avatar', () {
      // Aunque haga falta el último peldaño, sigue dando un avatar razonable.
      expect(kAvatarNormalizeSides.last, greaterThanOrEqualTo(256));
      expect(kAvatarNormalizeSides.first, greaterThanOrEqualTo(kAvatarMaxSide));
      // Estrictamente decreciente: cada intento pide menos que el anterior.
      for (var i = 1; i < kAvatarNormalizeSides.length; i++) {
        expect(
          kAvatarNormalizeSides[i],
          lessThan(kAvatarNormalizeSides[i - 1]),
        );
      }
    });
  });

  group('resizeAndEncodeJpeg', () {
    test('reduce el lado mayor hasta el máximo y mantiene la proporción', () {
      final result = resizeAndEncodeJpeg(_pngOf(width: 2048, height: 1024));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, kAvatarMaxSide);
      expect(decoded.height, kAvatarMaxSide ~/ 2);
    });

    test('usa el alto cuando la imagen es más alta que ancha', () {
      final result = resizeAndEncodeJpeg(_pngOf(width: 600, height: 1200));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.height, kAvatarMaxSide);
      expect(decoded.width, kAvatarMaxSide ~/ 2);
    });

    test('deja el recorte cuadrado en el tamaño máximo', () {
      final result = resizeAndEncodeJpeg(_pngOf(width: 1500, height: 1500));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, kAvatarMaxSide);
      expect(decoded.height, kAvatarMaxSide);
    });

    test('no amplía una imagen más pequeña que el máximo', () {
      final result = resizeAndEncodeJpeg(_pngOf(width: 120, height: 90));

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, 120);
      expect(decoded.height, 90);
    });

    test('siempre devuelve JPEG, entre a lo que entre', () {
      final result = resizeAndEncodeJpeg(_pngOf(width: 800, height: 800));

      // Cabecera JPEG (SOI + APP0/APP1).
      expect(result!.sublist(0, 2), [0xFF, 0xD8]);
    });

    test('el resultado pesa menos que el original sin procesar', () {
      final original = _pngOf(width: 2048, height: 2048);

      final result = resizeAndEncodeJpeg(original);

      expect(result!.length, lessThan(original.length));
    });

    test('devuelve null si los bytes no son una imagen', () {
      expect(resizeAndEncodeJpeg(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });
}
