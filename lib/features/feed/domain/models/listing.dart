class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    this.description,
    required this.city,
    this.neighborhood,
    required this.price,
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
  final String city;
  final String? neighborhood;
  final int price;
  final List<String> photos;
  final bool isFeatured;
  final bool isBusiness;
  final String status; // 'active' | 'closed'

  bool get isOffering => type == 'offering';

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      city: map['city'] as String,
      neighborhood: map['neighborhood'] as String?,
      price: map['price'] as int,
      photos: (map['photos'] as List<dynamic>? ?? const []).cast<String>(),
      isFeatured: map['is_featured'] as bool,
      isBusiness: map['is_business'] as bool,
      status: map['status'] as String,
    );
  }
}
