import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/data/profile_repository.dart';
import '../../data/feed_repository.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/listing_filter.dart';
import 'recent_searches_controller.dart';

class FeedController extends AsyncNotifier<List<Listing>> {
  ListingFilter _filter = const ListingFilter();

  ListingFilter get currentFilter => _filter;

  @override
  Future<List<Listing>> build() async {
    // Pantalla principal: publicaciones de la ciudad del propio perfil, si la
    // tiene rellenada (CU-09, comentarios).
    String? city;
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMyProfile();
      city = profile.city;
    } catch (_) {
      city = null;
    }
    _filter = ListingFilter(city: city);
    return ref.read(feedRepositoryProvider).fetchListings(_filter);
  }

  Future<void> search(ListingFilter filter) async {
    state = const AsyncLoading();
    _filter = filter;
    try {
      final results = await ref.read(feedRepositoryProvider).fetchListings(filter);
      await ref.read(recentSearchesControllerProvider.notifier).addSearch(filter);
      state = AsyncData(results);
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudieron cargar las publicaciones. Inténtalo de nuevo.',
        stackTrace,
      );
    }
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, List<Listing>>(
  FeedController.new,
);
