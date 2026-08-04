import 'package:room2gether/features/profile/data/user_search_repository.dart';
import 'package:room2gether/features/profile/domain/models/user_search_result.dart';

UserSearchResult fakeUserSearchResult({
  String id = 'user-2',
  String displayName = 'Nuria',
  String? avatarUrl,
  String? cityName,
  bool isBlocked = false,
}) {
  return UserSearchResult(
    id: id,
    displayName: displayName,
    avatarUrl: avatarUrl,
    cityName: cityName,
    isBlocked: isBlocked,
  );
}

class FakeUserSearchRepository implements UserSearchRepository {
  FakeUserSearchRepository({this.pages = const [], this.error});

  /// Respuesta por número de llamada: la primera llamada devuelve `pages[0]`,
  /// la segunda `pages[1]`, etc. Agotada la lista se devuelve vacío.
  final List<List<UserSearchResult>> pages;
  final Object? error;

  /// Retardo artificial de cada llamada, por índice de llamada. Sirve para
  /// forzar que una respuesta lenta aterrice después de otra más reciente.
  final Map<int, Duration> delays = {};

  final List<({String query, int limit, int offset})> calls = [];

  @override
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    required int limit,
    required int offset,
  }) async {
    final index = calls.length;
    calls.add((query: query, limit: limit, offset: offset));
    final delay = delays[index];
    if (delay != null) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return index < pages.length ? pages[index] : const [];
  }
}
