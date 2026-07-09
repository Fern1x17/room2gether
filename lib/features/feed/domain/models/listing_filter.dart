/// Criterios de búsqueda del feed: ciudad, barrio, precio y tipo — los tres
/// campos que RF-06 fija ("zona, precio, tipo").
///
/// La ciudad se filtra SIEMPRE por [cityId] (RF-15: nunca texto libre);
/// [cityName] viaja solo para poder pintar el chip de búsquedas recientes.
class ListingFilter {
  const ListingFilter({
    this.cityId,
    this.cityName,
    this.neighborhood,
    this.maxPrice,
    this.type,
  });

  final String? cityId;
  final String? cityName;
  final String? neighborhood;
  final int? maxPrice;
  final String? type; // 'seeking' | 'offering' | null (cualquiera)

  bool get isEmpty =>
      cityId == null &&
      neighborhood == null &&
      maxPrice == null &&
      type == null;

  ListingFilter copyWith({
    String? cityId,
    String? cityName,
    String? neighborhood,
    int? maxPrice,
    String? type,
  }) {
    return ListingFilter(
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      neighborhood: neighborhood ?? this.neighborhood,
      maxPrice: maxPrice ?? this.maxPrice,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'cityId': cityId,
    'cityName': cityName,
    'neighborhood': neighborhood,
    'maxPrice': maxPrice,
    'type': type,
  };

  /// Las búsquedas guardadas antes de RF-15 (con 'city' como texto) se leen
  /// sin ciudad: el texto libre ya no es un criterio válido.
  factory ListingFilter.fromJson(Map<String, dynamic> json) {
    return ListingFilter(
      cityId: json['cityId'] as String?,
      cityName: json['cityName'] as String?,
      neighborhood: json['neighborhood'] as String?,
      maxPrice: json['maxPrice'] as int?,
      type: json['type'] as String?,
    );
  }

  // cityName queda fuera de la igualdad: es presentación, no criterio.
  @override
  bool operator ==(Object other) {
    return other is ListingFilter &&
        other.cityId == cityId &&
        other.neighborhood == neighborhood &&
        other.maxPrice == maxPrice &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(cityId, neighborhood, maxPrice, type);
}
