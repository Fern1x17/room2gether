// Reducción de una foto usando el decodificador del navegador.
//
// Import condicional, igual que `link_opener`: en web delega en el pipeline de
// imágenes del propio navegador (`<img>` + `canvas`); en Android/iOS usa el
// stub, que devuelve `null` para que quien llame siga por el camino de
// `dart:ui`, que allí funciona de sobra.
//
// Existe porque en web `dart:ui` decodifica dentro del heap de WebAssembly, y
// una foto de móvil (12 MP y varios MB) puede no caber: falla al abrirla, y da
// igual a qué tamaño se pida el resultado, porque el coste está en decodificar
// el original. El navegador, en cambio, decodifica imágenes grandes en su
// propio pipeline nativo todos los días.
export 'image_downscaler_stub.dart'
    if (dart.library.js_interop) 'image_downscaler_web.dart';
