import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed_repository.dart';
import '../../domain/models/listing.dart';

final listingDetailProvider = FutureProvider.family<Listing, String>((ref, id) {
  return ref.read(feedRepositoryProvider).fetchListingById(id);
});
