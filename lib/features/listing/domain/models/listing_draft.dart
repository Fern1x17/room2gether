/// Datos para crear una publicación (CU-06). Según el tipo:
/// - 'offering' (ya tiene piso): price obligatorio, fotos obligatorias,
///   barrio obligatorio.
/// - 'seeking' (busca piso): rango budgetMin-budgetMax obligatorio y el
///   barrio puede quedar como "cualquiera" (null).
class ListingDraft {
  const ListingDraft({
    required this.type,
    required this.title,
    this.description,
    required this.cityId,
    this.neighborhood,
    this.price,
    this.budgetMin,
    this.budgetMax,
  });

  final String type; // 'offering' | 'seeking'
  final String title;
  final String? description;
  final String cityId; // siempre una ciudad del catálogo (RF-15)
  final String? neighborhood;
  final int? price;
  final int? budgetMin;
  final int? budgetMax;

  bool get isOffering => type == 'offering';
}
