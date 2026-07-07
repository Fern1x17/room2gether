import 'package:roomie/features/feed/domain/models/listing.dart';
import 'package:roomie/features/listing/data/listing_repository.dart';
import 'package:roomie/features/listing/domain/models/listing_draft.dart';

class FakeListingRepository implements ListingRepository {
  FakeListingRepository({
    this.activeListings = 0,
    this.createError,
    this.deleteError,
    this.updateError,
    List<Listing>? myListings,
  }) : myListings = myListings ?? [];

  int activeListings;
  final Object? createError;
  final Object? deleteError;
  final Object? updateError;
  final List<Listing> myListings;
  ListingDraft? lastCreatedDraft;
  List<String>? lastPhotoUrls;
  int uploadedPhotoCount = 0;
  final List<String> deletedIds = [];
  String? lastUpdatedId;
  ListingDraft? lastUpdatedDraft;

  @override
  Future<int> countMyActiveListings() async => activeListings;

  @override
  Future<List<String>> uploadPhotos(List<PendingPhoto> photos) async {
    uploadedPhotoCount = photos.length;
    return [
      for (var i = 0; i < photos.length; i++) 'https://example.com/photo_$i.jpg',
    ];
  }

  @override
  Future<void> createListing(
    ListingDraft draft, {
    required List<String> photoUrls,
  }) async {
    if (createError != null) throw createError!;
    lastCreatedDraft = draft;
    lastPhotoUrls = photoUrls;
  }

  @override
  Future<List<Listing>> fetchMyListings() async => myListings;

  @override
  Future<void> deleteListing(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedIds.add(id);
    myListings.removeWhere((listing) => listing.id == id);
  }

  @override
  Future<void> updateListing(
    String id,
    ListingDraft draft, {
    required List<String> photoUrls,
  }) async {
    if (updateError != null) throw updateError!;
    lastUpdatedId = id;
    lastUpdatedDraft = draft;
    lastPhotoUrls = photoUrls;
  }
}
