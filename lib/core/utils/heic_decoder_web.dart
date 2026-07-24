import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Ruta del decodificador dentro de `web/`. Va servido desde el propio sitio,
/// no desde un CDN ajeno: así no depende de terceros ni filtra a los usuarios.
const String _decoderScriptPath = 'heic/heic2any.min.js';

/// Cuánto se espera a que el decodificador se descargue y a que decodifique.
/// Es un fichero de ~1,5 MB y la decodificación no es barata, así que da margen.
const Duration _kHeicTimeout = Duration(seconds: 45);

@JS('heic2any')
external JSPromise<JSAny?> _heic2any(JSObject options);

Completer<bool>? _scriptLoad;

/// Descarga el decodificador **la primera vez que hace falta**.
///
/// Este es el motivo de todo el montaje: pesa ~1,5 MB y solo lo necesita quien
/// elige una foto de iPhone. Quien no, no descarga ni un byte de más.
Future<bool> _ensureDecoderLoaded() {
  final pending = _scriptLoad;
  if (pending != null) return pending.future;

  final completer = Completer<bool>();
  _scriptLoad = completer;

  final script = web.HTMLScriptElement()
    ..src = _decoderScriptPath
    ..async = true;
  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete(true);
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) completer.complete(false);
  });
  web.document.head!.appendChild(script);

  return completer.future;
}

/// Convierte una foto HEIC en JPEG, o `null` si no se puede.
///
/// Quien llame debe haber comprobado antes que el fichero **es** HEIC mirando
/// su cabecera: la extensión y el MIME que da el sistema mienten a menudo.
Future<Uint8List?> decodeHeicToJpeg(Uint8List bytes) async {
  try {
    final loaded = await _ensureDecoderLoaded().timeout(_kHeicTimeout);
    if (!loaded) return null;

    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/heic'),
    );
    final options = JSObject()
      ..setProperty('blob'.toJS, blob)
      ..setProperty('toType'.toJS, 'image/jpeg'.toJS)
      ..setProperty('quality'.toJS, 0.9.toJS);

    final result = await _heic2any(options).toDart.timeout(_kHeicTimeout);
    // Con varias imágenes dentro (ráfagas, Live Photos) devuelve una lista;
    // en ese caso vale la primera.
    final decoded = result.isA<JSArray>()
        ? (result as JSArray).toDart.first as web.Blob
        : result as web.Blob;

    final buffer = await decoded.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}
