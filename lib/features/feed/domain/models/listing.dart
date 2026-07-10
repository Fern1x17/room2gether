class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    this.description,
    required this.cityId,
    this.cityName,
    this.neighborhood,
    this.addressPlaceId,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.addressIsPublic = false,
    this.price,
    this.budgetMin,
    this.budgetMax,
    required this.photos,
    required this.isFeatured,
    required this.isBusiness,
    required this.status,
  });

  final String id;
  final String ownerId;
  final String type; // 'seeking' | 'offering'
  final String title;
  final String? description;
  final String cityId;
  final String? cityName; // solo lectura (join con cities)
  final String? neighborhood;

  // Dirección exacta (join con listing_addresses). RLS solo devuelve la fila
  // si es pública o si la publicación es del usuario actual.
  final String? addressPlaceId;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final bool addressIsPublic;

  final int? price; // solo 'offering'
  final int? budgetMin; // solo 'seeking'
  final int? budgetMax;
  final List<String> photos;
  final bool isFeatured;
  final bool isBusiness;
  final String status; // 'active' | 'closed'

  bool get isOffering => type == 'offering';

  /// Texto de precio para mostrar: precio mensual (offering) o rango de
  /// presupuesto (seeking).
  String get priceLabel => isOffering
      ? '${price ?? '-'} €/mes'
      : '${budgetMin ?? '-'}–${budgetMax ?? '-'} €/mes';

  factory Listing.fromMap(Map<String, dynamic> map) {
    final address = map['address'] as Map<String, dynamic>?;
    return Listing(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      cityId: map['city_id'] as String,
      cityName: (map['city'] as Map<String, dynamic>?)?['name'] as String?,
      neighborhood: map['neighborhood'] as String?,
      addressPlaceId: address?['google_place_id'] as String?,
      formattedAddress: address?['formatted_address'] as String?,
      latitude: (address?['latitude'] as num?)?.toDouble(),
      longitude: (address?['longitude'] as num?)?.toDouble(),
      addressIsPublic: address?['is_public'] as bool? ?? false,
      price: map['price'] as int?,
      budgetMin: map['budget_min'] as int?,
      budgetMax: map['budget_max'] as int?,
      photos: (map['photos'] as List<dynamic>? ?? const []).cast<String>(),
      isFeatured: map['is_featured'] as bool,
      isBusiness: map['is_business'] as bool,
      status: map['status'] as String,
    );
  }
}
