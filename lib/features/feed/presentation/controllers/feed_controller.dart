import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../moderation/data/moderation_repository.dart';
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
      final profile = await ref
          .read(profileRepositoryProvider)
          .fetchMyProfile();
      city = profile.city;
    } catch (_) {
      city = null;
    }
    _filter = ListingFilter(city: city);
    return _fetchVisible(_filter);
  }

  Future<void> search(ListingFilter filter) async {
    state = const AsyncLoading();
    _filter = filter;
    try {
      final results = await _fetchVisible(filter);
      await ref
          .read(recentSearchesControllerProvider.notifier)
          .addSearch(filter);
      state = AsyncData(results);
    } catch (error, stackTrace) {
      state = AsyncError(
        'No se pudieron cargar las publicaciones. Inténtalo de nuevo.',
        stackTrace,
      );
    }
  }

  /// Aplica el filtro y excluye publicaciones de usuarios bloqueados
  /// (efecto del bloqueo de CU-11: "no ver sus publicaciones").
  Future<List<Listing>> _fetchVisible(ListingFilter filter) async {
    final results = await ref
        .read(feedRepositoryProvider)
        .fetchListings(filter);
    final blocked = await ref
        .read(moderationRepositoryProvider)
        .fetchMyBlockedIds();
    if (blocked.isEmpty) return results;
    return results
        .where((listing) => !blocked.contains(listing.ownerId))
        .toList();
  }
}

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Listing>>(FeedController.new);
