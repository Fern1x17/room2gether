import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/feed/domain/models/listing.dart';
import 'package:room2gether/features/feed/domain/models/listing_filter.dart';

Listing fakeListing({
  String id = 'listing-1',
  String ownerId = 'user-1',
  String? ownerName = 'Ana',
  String type = 'offering',
  String title = 'Habitación luminosa',
  String cityId = 'city-vigo',
  String? cityName = 'Vigo',
  String? neighborhood = 'Ruzafa',
  int price = 400,
  List<String> photos = const [],
  bool isFeatured = false,
}) {
  return Listing(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    type: type,
    title: title,
    cityId: cityId,
    cityName: cityName,
    neighborhood: neighborhood,
    price: price,
    photos: photos,
    isFeatured: isFeatured,
    isBusiness: false,
    status: 'active',
  );
}

class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository({List<Listing>? listings, this.fetchError})
    : listings = listings ?? [fakeListing()];

  final List<Listing> listings;
  final Object? fetchError;
  ListingFilter? lastFilter;

  @override
  Future<List<Listing>> fetchListings(ListingFilter filter) async {
    if (fetchError != null) throw fetchError!;
    lastFilter = filter;
    return listings.where((listing) {
      if (filter.cityId != null && listing.cityId != filter.cityId) {
        return false;
      }
      if (filter.neighborhood != null &&
          listing.neighborhood != filter.neighborhood) {
        return false;
      }
      final effectivePrice = listing.price ?? listing.budgetMax;
      if (filter.maxPrice != null &&
          (effectivePrice == null || effectivePrice > filter.maxPrice!)) {
        return false;
      }
      if (filter.type != null && listing.type != filter.type) return false;
      return true;
    }).toList();
  }

  @override
  Future<Listing> fetchListingById(String id) async {
    if (fetchError != null) throw fetchError!;
    return listings.firstWhere((listing) => listing.id == id);
  }

  @override
  Future<List<Listing>> fetchListingsByOwner(String ownerId) async {
    if (fetchError != null) throw fetchError!;
    return listings
        .where(
          (listing) => listing.ownerId == ownerId && listing.status == 'active',
        )
        .toList();
  }
}
