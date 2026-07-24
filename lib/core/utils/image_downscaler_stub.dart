import 'dart:typed_data';

/// Implementación por defecto de [downscaleWithPlatform] fuera de web.
///
/// Devuelve `null` a propósito: en Android/iOS la decodificación de `dart:ui`
/// la hace Skia con la memoria del proceso, sin el techo del heap de
/// WebAssembly, así que no hace falta un camino aparte.
Future<Uint8List?> downscaleWithPlatform(
  Uint8List bytes, {
  required int maxSide,
}) async {
  return null;
}
