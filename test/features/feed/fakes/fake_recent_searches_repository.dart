import 'package:room2gether/features/feed/data/recent_searches_repository.dart';
import 'package:room2gether/features/feed/domain/models/listing_filter.dart';

class FakeRecentSearchesRepository implements RecentSearchesRepository {
  final List<ListingFilter> _saved = [];

  @override
  Future<List<ListingFilter>> load() async => List.unmodifiable(_saved);

  @override
  Future<void> save(ListingFilter filter) async {
    _saved
      ..removeWhere((existing) => existing == filter)
      ..insert(0, filter);
  }
}
