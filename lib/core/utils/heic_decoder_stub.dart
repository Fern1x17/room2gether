import 'dart:typed_data';

/// Implementación por defecto de [decodeHeicToJpeg] fuera de web.
///
/// Devuelve `null` a propósito: en Android/iOS la decodificación nativa ya
/// entiende HEIC, así que no hace falta un decodificador aparte.
Future<Uint8List?> decodeHeicToJpeg(Uint8List bytes) async => null;
