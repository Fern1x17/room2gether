/// Datos para crear una publicación (CU-06). Según el tipo:
/// - 'offering' (ya tiene piso): price obligatorio, fotos obligatorias,
///   ubicación (dirección o barrio) obligatoria.
/// - 'seeking' (busca piso): rango budgetMin-budgetMax obligatorio y la
///   ubicación puede quedar como "cualquiera" (null).
///
/// La dirección exacta (si la hay) se guarda en `listing_addresses` con su
/// flag de privacidad [showExactAddress]; el barrio queda en
/// `listings.neighborhood` (texto) y es lo que se muestra si la dirección no
/// es pública.
class ListingDraft {
  const ListingDraft({
    required this.type,
    required this.title,
    this.description,
    required this.cityId,
    this.neighborhood,
    this.addressPlaceId,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.showExactAddress = false,
    this.price,
    this.budgetMin,
    this.budgetMax,
  });

  final String type; // 'offering' | 'seeking'
  final String title;
  final String? description;
  final String cityId; // siempre una fila de cities (RF-15)
  final String? neighborhood;

  // Dirección exacta (Google Places); null si solo se indicó barrio.
  final String? addressPlaceId;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  /// true = el usuario eligió mostrar la dirección completa (CU-06).
  final bool showExactAddress;

  final int? price;
  final int? budgetMin;
  final int? budgetMax;

  bool get isOffering => type == 'offering';

  bool get hasExactAddress => formattedAddress != null;
}
