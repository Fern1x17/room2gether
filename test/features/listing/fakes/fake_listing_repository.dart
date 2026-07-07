import 'package:roomie/features/listing/data/listing_repository.dart';
import 'package:roomie/features/listing/domain/models/listing_draft.dart';

class FakeListingRepository implements ListingRepository {
  FakeListingRepository({this.activeListings = 0, this.createError});

  int activeListings;
  final Object? createError;
  ListingDraft? lastCreatedDraft;
  List<String>? lastPhotoUrls;
  int uploadedPhotoCount = 0;

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
}
