// Decodificación de fotos HEIC (las que hace un iPhone) en el navegador.
//
// Import condicional, igual que `link_opener` e `image_downscaler`. Solo la
// web necesita esto: en Android, `dart:ui` decodifica con Skia, que entiende
// HEIC desde Android 8, así que el stub devuelve `null` y no se usa.
//
// Ningún navegador salvo Safari sabe abrir HEIC, y el paquete `image` tampoco.
// Como además algunas apps renombran el fichero a `.jpg` al compartirlo, no se
// puede confiar ni en la extensión ni en el MIME: quien llame debe decidir por
// la cabecera real del fichero (`describeImageBytes`).
export 'heic_decoder_stub.dart'
    if (dart.library.js_interop) 'heic_decoder_web.dart';
