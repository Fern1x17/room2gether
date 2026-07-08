import 'package:roomie/features/feed/data/feed_repository.dart';
import 'package:roomie/features/feed/domain/models/listing.dart';
import 'package:roomie/features/feed/domain/models/listing_filter.dart';

Listing fakeListing({
  String id = 'listing-1',
  String ownerId = 'user-1',
  String type = 'offering',
  String title = 'Habitación luminosa',
  String city = 'Valencia',
  String? neighborhood = 'Ruzafa',
  int price = 400,
  bool isFeatured = false,
}) {
  return Listing(
    id: id,
    ownerId: ownerId,
    type: type,
    title: title,
    city: city,
    neighborhood: neighborhood,
    price: price,
    photos: const [],
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
      if (filter.city != null && listing.city != filter.city) return false;
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
    return listings.firstWhere((listing) => listing.id == id);
  }
}
