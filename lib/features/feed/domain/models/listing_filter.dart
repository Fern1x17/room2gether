/// Criterios de búsqueda del feed: ciudad, barrio, precio y tipo — los tres
/// campos que RF-06 fija ("zona, precio, tipo").
class ListingFilter {
  const ListingFilter({this.city, this.neighborhood, this.maxPrice, this.type});

  final String? city;
  final String? neighborhood;
  final int? maxPrice;
  final String? type; // 'seeking' | 'offering' | null (cualquiera)

  bool get isEmpty =>
      city == null && neighborhood == null && maxPrice == null && type == null;

  ListingFilter copyWith({
    String? city,
    String? neighborhood,
    int? maxPrice,
    String? type,
  }) {
    return ListingFilter(
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      maxPrice: maxPrice ?? this.maxPrice,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'neighborhood': neighborhood,
    'maxPrice': maxPrice,
    'type': type,
  };

  factory ListingFilter.fromJson(Map<String, dynamic> json) {
    return ListingFilter(
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      maxPrice: json['maxPrice'] as int?,
      type: json['type'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ListingFilter &&
        other.city == city &&
        other.neighborhood == neighborhood &&
        other.maxPrice == maxPrice &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(city, neighborhood, maxPrice, type);
}
