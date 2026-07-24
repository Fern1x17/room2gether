import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Lado máximo (px) de la foto de perfil una vez recortada.
///
/// El avatar se pinta con `radius: 48` (96 dp); a 3x de densidad son 288 px
/// reales. 512 deja margen para usos más grandes (una futura cabecera de
/// perfil) sin gastar ancho de banda: pesa ~40–70 KB en JPEG de calidad 85,
/// frente a los ~250 KB de la imagen sin procesar.
const int kAvatarMaxSide = 512;

/// Calidad JPEG de la foto de perfil.
const int kAvatarJpegQuality = 85;

/// Reduce [bytes] para que su lado mayor no supere [maxSide] y lo recodifica
/// en JPEG con calidad [quality].
///
/// Nunca amplía: una imagen ya menor que [maxSide] solo se recomprime. Devuelve
/// `null` si los bytes no son una imagen decodificable.
///
/// Función pura (sin Flutter ni plataforma) para poder testearla sola; el
/// trabajo pesado se lanza desde [resizeAvatarBytes].
Uint8List? resizeAndEncodeJpeg(
  Uint8List bytes, {
  int maxSide = kAvatarMaxSide,
  int quality = kAvatarJpegQuality,
}) {
  // decodeImage no siempre devuelve null con bytes corruptos: alguno de los
  // decodificadores que husmea la cabecera puede lanzar. Un fichero ilegible
  // debe traducirse en "no se pudo procesar", nunca en un fallo sin capturar.
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  final longestSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = longestSide <= maxSide
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
          interpolation: img.Interpolation.average,
        );

  return img.encodeJpg(resized, quality: quality);
}

Uint8List? _resizeAvatarIsolate(Uint8List bytes) => resizeAndEncodeJpeg(bytes);

/// Versión asíncrona de [resizeAndEncodeJpeg] para usar desde la UI.
///
/// `compute` mueve el decode/encode a otro isolate en móvil (no bloquea la
/// animación del loader); en web no hay isolates y se ejecuta en el mismo hilo,
/// que es exactamente lo que haría una llamada directa. No es una decisión de
/// plataforma nuestra: la misma llamada sirve para las dos.
Future<Uint8List?> resizeAvatarBytes(Uint8List bytes) {
  return compute(_resizeAvatarIsolate, bytes);
}
