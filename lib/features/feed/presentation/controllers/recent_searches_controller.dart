import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/recent_searches_repository.dart';
import '../../domain/models/listing_filter.dart';

class RecentSearchesController extends AsyncNotifier<List<ListingFilter>> {
  @override
  Future<List<ListingFilter>> build() {
    final repository = ref.read(recentSearchesRepositoryProvider);
    return repository.load();
  }

  Future<void> addSearch(ListingFilter filter) async {
    final repository = ref.read(recentSearchesRepositoryProvider);
    await repository.save(filter);
    state = AsyncData(await repository.load());
  }
}

final recentSearchesControllerProvider =
    AsyncNotifierProvider<RecentSearchesController, List<ListingFilter>>(
      RecentSearchesController.new,
    );
