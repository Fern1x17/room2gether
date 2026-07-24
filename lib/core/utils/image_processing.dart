import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'heic_decoder.dart';
import 'image_downscaler.dart';

/// Lado máximo (px) de la foto de perfil una vez recortada.
///
/// El avatar se pinta con `radius: 48` (96 dp); a 3x de densidad son 288 px
/// reales. 512 deja margen para usos más grandes (una futura cabecera de
/// perfil) sin gastar ancho de banda: pesa ~40–70 KB en JPEG de calidad 85,
/// frente a los ~250 KB de la imagen sin procesar.
const int kAvatarMaxSide = 512;

/// Calidad JPEG de la foto de perfil.
const int kAvatarJpegQuality = 85;

/// Lados que [normalizeForCrop] intenta, de mayor a menor.
///
/// Se empieza bajo a propósito: el avatar acaba en [kAvatarMaxSide] pase lo que
/// pase, así que darle al recortador más de 1024 px es trabajo que se tira, y
/// ese trabajo lo paga el hilo principal del navegador en móvil. Se baja hasta
/// 256 px, que sigue dando un avatar decente, antes de rendirse: es preferible
/// una foto un poco menos nítida a no poder ponerla.
const List<int> kAvatarNormalizeSides = <int>[1024, 768, 512, 384, 256];

/// Tiempo máximo por intento de [normalizeForCrop].
///
/// Sin esto, un intento que no termina nunca deja la pantalla colgada y no se
/// llega a probar un tamaño menor. Con esto, "tarda demasiado" cuenta como
/// fallo y se reintenta más pequeño. Es holgado a propósito: en un móvil lento
/// abrir una foto de 12 MP puede tardar unos segundos, y es preferible esperar
/// a rendirse.
const Duration kAvatarNormalizeTimeout = Duration(seconds: 20);

/// Deja una foto recién elegida en un JPEG pequeño que el recortador pueda
/// abrir, o `null` si no hay manera.
///
/// Existe porque `crop_your_image` decodifica con el paquete `image`, en Dart:
/// no entiende HEIC ni todos los WebP (la foto se queda cargando para siempre)
/// y en web trabaja en el hilo principal, donde una imagen grande congela la
/// pantalla. Aquí la decodificación la hace **la plataforma** (`dart:ui`, que
/// en web es el decodificador del navegador y en Android es Skia), que sí
/// entiende todo lo que el sistema sabe abrir y además reescala al vuelo.
///
/// Orden de los intentos:
///
/// 1. **El navegador** ([downscaleWithPlatform], solo en web). Va primero
///    porque es el único que puede con una foto que `dart:ui` no logra ni
///    abrir: decodifica fuera del heap de WebAssembly. Fuera de web devuelve
///    `null` al instante y no cuesta nada.
/// 2. **`dart:ui`**, bajando por [kAvatarNormalizeSides].
/// 3. **El paquete `image`**, en Dart, como último recurso.
///
/// Ojo con la escalera del punto 2: bajar el tamaño **pedido** no abarata
/// decodificar el original, que es donde está el coste. Sirve para fallos de
/// memoria al construir el resultado, no para "esta foto no se puede abrir".
Future<Uint8List?> normalizeForCrop(
  Uint8List bytes, {
  List<int> sides = kAvatarNormalizeSides,
  Duration timeout = kAvatarNormalizeTimeout,
  void Function(Object error)? onAttemptFailed,
}) async {
  var source = bytes;

  // Paso previo solo para HEIC (fotos de iPhone). Se decide por la cabecera
  // real: al compartirlas, muchas apps las renombran a `.jpg` y las anuncian
  // como `image/jpeg`, así que ni la extensión ni el MIME sirven. Fuera de web
  // esto devuelve `null` al instante y no cuesta nada.
  if (isHeicContainer(describeImageBytes(bytes))) {
    final asJpeg = await decodeHeicToJpeg(bytes);
    if (asJpeg != null) {
      source = asJpeg;
    } else {
      onAttemptFailed?.call(
        StateError('No se pudo convertir la foto HEIC a JPEG'),
      );
    }
  }

  try {
    final viaPlatform = await downscaleWithPlatform(
      source,
      maxSide: sides.first,
    ).timeout(timeout);
    if (viaPlatform != null) return viaPlatform;
  } catch (error) {
    onAttemptFailed?.call(error);
  }

  for (final side in sides) {
    try {
      final normalized = await _decodeAndEncodeJpeg(
        source,
        maxSide: side,
      ).timeout(timeout);
      if (normalized != null) return normalized;
      onAttemptFailed?.call(StateError('sin imagen a $side px'));
    } catch (error) {
      // Falló o tardó demasiado: siguiente intento, más pequeño.
      onAttemptFailed?.call(error);
    }
  }

  // Último recurso: decodificar en Dart. Es más lento y entiende menos
  // formatos, pero salva el caso de que `dart:ui` no pueda con este fichero.
  try {
    final fallback = await compute(
      _resizeForCropIsolate,
      source,
    ).timeout(timeout);
    if (fallback != null) return fallback;
    onAttemptFailed?.call(StateError('el decodificador de Dart tampoco pudo'));
  } catch (error) {
    onAttemptFailed?.call(error);
  }
  return null;
}

Uint8List? _resizeForCropIsolate(Uint8List bytes) => resizeAndEncodeJpeg(
  bytes,
  maxSide: kAvatarNormalizeSides.first,
  quality: 90,
);

/// Decodifica con la plataforma reescalando al vuelo y recodifica en JPEG.
Future<Uint8List?> _decodeAndEncodeJpeg(
  Uint8List bytes, {
  required int maxSide,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final ui.ImageDescriptor descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
  } catch (_) {
    buffer.dispose();
    return null; // La plataforma tampoco sabe abrir este fichero.
  }

  // Ambas dimensiones explícitas: así el reescalado no depende de cómo trate
  // `dart:ui` una dimensión omitida.
  final longestSide = descriptor.width > descriptor.height
      ? descriptor.width
      : descriptor.height;
  final scale = longestSide <= maxSide ? 1.0 : maxSide / longestSide;
  final targetWidth = (descriptor.width * scale).round().clamp(1, maxSide);
  final targetHeight = (descriptor.height * scale).round().clamp(1, maxSide);

  ui.Image? image;
  ui.Image? scaled;
  try {
    final codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    image = frame.image;
    codec.dispose();

    // `targetWidth`/`targetHeight` son una *petición*: no todos los códecs los
    // respetan (en web depende del navegador). Si el códec los ignoró, aquí
    // habría una imagen a tamaño completo, y leerla en RGBA serían decenas de
    // MB que luego habría que recomprimir en Dart. Se vuelve a escalar con la
    // GPU para que lo que sigue esté acotado pase lo que pase.
    if (image.width != targetWidth || image.height != targetHeight) {
      scaled = await _scaleImage(image, targetWidth, targetHeight);
    }
    final result = scaled ?? image;

    final rgba = await result.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) return null;

    // Nota: `rawRgba` viene con alfa premultiplicado. Da igual para una foto
    // (opaca), y el JPEG no tiene canal alfa de todos modos.
    final decoded = img.Image.fromBytes(
      width: result.width,
      height: result.height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return img.encodeJpg(decoded, quality: 90);
  } finally {
    scaled?.dispose();
    image?.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}

/// Redibuja [source] en [width]x[height]. El escalado lo hace el motor de
/// pintado, no Dart, así que no bloquea el hilo principal en web.
Future<ui.Image> _scaleImage(ui.Image source, int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    source,
    ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

/// Identifica el formato real de [bytes] por su cabecera, sin decodificar.
///
/// La extensión y el MIME que da el selector son lo que *dice* el sistema; esto
/// es lo que el fichero *es*. Cuando ningún decodificador puede con una imagen,
/// es el dato que distingue "formato que no soportamos" de "bytes corruptos".
String describeImageBytes(Uint8List bytes) {
  if (bytes.length < 12) return 'truncado(${bytes.length}B)';

  if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'JPEG';
  if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'PNG';
  if (bytes[0] == 0x47 && bytes[1] == 0x49) return 'GIF';

  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  if (riff == 'RIFF' && String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'WEBP';
  }
  // HEIC, HEIF y AVIF son contenedores ISO-BMFF: 'ftyp' + marca.
  if (String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    return 'ISOBMFF/${String.fromCharCodes(bytes.sublist(8, 12))}';
  }

  final head = bytes
      .sublist(0, 4)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return 'desconocido($head)';
}

/// `true` si [describeImageBytes] identificó un contenedor ISO-BMFF (HEIC,
/// HEIF o AVIF), que es lo que graba un iPhone y ningún navegador salvo Safari
/// sabe abrir.
bool isHeicContainer(String description) => description.startsWith('ISOBMFF');

/// Recorta [bytes] a un cuadrado centrado y lo deja en [maxSide] px, JPEG.
///
/// Es la salida de emergencia del recorte manual: si el recortador no consigue
/// abrir una foto, el usuario no se queda sin poder usarla. Trabaja sobre lo
/// que devuelve [normalizeForCrop], así que la imagen de entrada ya es pequeña
/// y decodificable.
Uint8List? cropSquareCenterAndEncodeJpeg(
  Uint8List bytes, {
  int maxSide = kAvatarMaxSide,
  int quality = kAvatarJpegQuality,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = side <= maxSide
      ? square
      : img.copyResize(
          square,
          width: maxSide,
          height: maxSide,
          interpolation: img.Interpolation.average,
        );
  return img.encodeJpg(resized, quality: quality);
}

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
