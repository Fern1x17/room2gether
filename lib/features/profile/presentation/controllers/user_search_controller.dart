import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../data/user_search_repository.dart';
import '../../domain/models/user_search_result.dart';

/// Mínimo de caracteres para lanzar una búsqueda. Va emparejado con el mismo
/// suelo dentro de `search_profiles`: con una sola letra, `ilike '%a%'` acaba
/// en escaneo secuencial por muchos índices que haya.
const int kUserSearchMinQueryLength = 2;

/// Resultados por página.
const int kUserSearchPageSize = 20;

/// Espera antes de consultar mientras se teclea.
const Duration kUserSearchDebounce = Duration(milliseconds: 350);

/// Estado del buscador de usuarios (CU-20).
///
/// El "cargando" es un campo del estado y no un `AsyncLoading`: al teclear
/// interesa seguir viendo los resultados anteriores mientras llega la nueva
/// respuesta, en vez de vaciar la lista en cada pulsación.
@immutable
class UserSearchState {
  const UserSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
  });

  /// Texto buscado, ya sin espacios sobrantes.
  final String query;
  final List<UserSearchResult> results;

  /// Hay una búsqueda en curso (incluye la espera del debounce).
  final bool isSearching;

  /// Se está trayendo la página siguiente.
  final bool isLoadingMore;

  /// La última página vino llena, así que puede haber más.
  final bool hasMore;

  final String? errorMessage;

  /// Lo escrito aún no llega al mínimo: estado inicial de la pantalla.
  bool get isQueryTooShort => query.length < kUserSearchMinQueryLength;

  UserSearchState copyWith({
    String? query,
    List<UserSearchResult>? results,
    bool? isSearching,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return UserSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class UserSearchController extends AutoDisposeNotifier<UserSearchState> {
  /// Identifica la última búsqueda lanzada. Sirve para las dos cosas a la vez:
  /// cancelar el debounce cuando se sigue tecleando y descartar la respuesta
  /// de una petición en vuelo que ya no corresponde a lo escrito. Sin esto,
  /// una consulta lenta puede aterrizar después de otra más reciente y
  /// sobrescribir la lista con resultados viejos.
  int _searchId = 0;

  @override
  UserSearchState build() {
    // Al cambiar de cuenta cambian los bloqueos, y con ellos los resultados.
    ref.watch(currentUserIdProvider);
    // Al salir de la pantalla, cualquier petición en vuelo queda descartada.
    ref.onDispose(() => _searchId++);
    return const UserSearchState();
  }

  /// Nuevo texto en el campo de búsqueda.
  Future<void> updateQuery(String rawQuery) async {
    final query = rawQuery.trim();
    final searchId = ++_searchId;

    if (query.length < kUserSearchMinQueryLength) {
      state = UserSearchState(query: query);
      return;
    }

    state = state.copyWith(query: query, isSearching: true);

    await Future<void>.delayed(kUserSearchDebounce);
    if (searchId != _searchId) return;

    await _run(searchId, query);
  }

  /// Reintento tras un error, con el texto que ya hay escrito.
  Future<void> retry() async {
    final query = state.query;
    if (query.length < kUserSearchMinQueryLength) return;
    final searchId = ++_searchId;
    state = state.copyWith(query: query, isSearching: true);
    await _run(searchId, query);
  }

  /// Página siguiente, al llegar al final de la lista.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isSearching) return;

    final searchId = _searchId;
    final query = state.query;
    final offset = state.results.length;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await ref
          .read(userSearchRepositoryProvider)
          .searchUsers(
            query: query,
            limit: kUserSearchPageSize,
            offset: offset,
          );
      if (searchId != _searchId) return;
      state = state.copyWith(
        results: [...state.results, ...page],
        isLoadingMore: false,
        hasMore: page.length == kUserSearchPageSize,
      );
    } catch (_) {
      if (searchId != _searchId) return;
      // Fallar al pedir más no debe tirar los resultados ya visibles: se corta
      // la paginación y la lista se queda como está.
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }

  Future<void> _run(int searchId, String query) async {
    try {
      final results = await ref
          .read(userSearchRepositoryProvider)
          .searchUsers(query: query, limit: kUserSearchPageSize, offset: 0);
      if (searchId != _searchId) return;
      state = UserSearchState(
        query: query,
        results: results,
        hasMore: results.length == kUserSearchPageSize,
      );
    } catch (_) {
      if (searchId != _searchId) return;
      state = UserSearchState(
        query: query,
        errorMessage: 'No se pudo buscar. Inténtalo de nuevo.',
      );
    }
  }
}

final userSearchControllerProvider =
    AutoDisposeNotifierProvider<UserSearchController, UserSearchState>(
      UserSearchController.new,
    );
