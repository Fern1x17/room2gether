import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Reduce [bytes] a un JPEG de como mucho [maxSide] px usando el navegador.
///
/// La foto se decodifica en un `<img>` —pipeline nativo del navegador, fuera
/// del heap de WebAssembly— y se redibuja en un `canvas` del tamaño final. Así
/// una foto de 12 MP que `dart:ui` no puede ni abrir sí pasa.
///
/// Se usa `toDataURL` y no `toBlob` a propósito: `toBlob` entrega el resultado
/// por callback y el navegador le pasa `null` cuando no puede producirlo, lo
/// que deja colgado a quien espere ese callback (es el fallo que tiene
/// `image_picker_for_web`). `toDataURL` es síncrono: o devuelve la cadena o
/// lanza.
Future<Uint8List?> downscaleWithPlatform(
  Uint8List bytes, {
  required int maxSide,
}) async {
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final image = web.HTMLImageElement();
  try {
    final loaded = Completer<void>();
    image.onLoad.listen((_) {
      if (!loaded.isCompleted) loaded.complete();
    });
    image.onError.listen((_) {
      if (!loaded.isCompleted) {
        loaded.completeError(
          StateError('El navegador no pudo abrir esta imagen'),
        );
      }
    });
    image.src = url;
    await loaded.future;

    final width = image.naturalWidth;
    final height = image.naturalHeight;
    if (width == 0 || height == 0) return null;

    final longestSide = width > height ? width : height;
    final scale = longestSide <= maxSide ? 1.0 : maxSide / longestSide;
    final targetWidth = (width * scale).round().clamp(1, maxSide);
    final targetHeight = (height * scale).round().clamp(1, maxSide);

    final canvas = web.HTMLCanvasElement()
      ..width = targetWidth
      ..height = targetHeight;
    canvas.context2D.drawImage(
      image,
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );

    final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
    final separator = dataUrl.indexOf(',');
    if (separator == -1) return null;
    return base64Decode(dataUrl.substring(separator + 1));
  } finally {
    image.src = '';
    web.URL.revokeObjectURL(url);
  }
}
