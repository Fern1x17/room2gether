import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_search_result.dart';
import '../controllers/user_search_controller.dart';

/// Resultados del buscador de usuarios con sus estados (CU-20).
///
/// Widget de contenido compartido: no sabe en qué shell está: solo pinta la
/// lista y avisa por [onUserTap] de la fila pulsada.
class UserSearchResults extends ConsumerStatefulWidget {
  const UserSearchResults({super.key, required this.onUserTap});

  final ValueChanged<UserSearchResult> onUserTap;

  @override
  ConsumerState<UserSearchResults> createState() => _UserSearchResultsState();
}

class _UserSearchResultsState extends ConsumerState<UserSearchResults> {
  /// Píxeles desde el final a los que se pide la página siguiente.
  static const _loadMoreThreshold = 320.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // El propio controlador ignora la llamada si no hay más páginas o si ya
      // hay una en vuelo, así que no hace falta guardarlo aquí.
      ref.read(userSearchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSearchControllerProvider);
    final theme = Theme.of(context);

    if (state.errorMessage != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        message: state.errorMessage!,
        action: FilledButton(
          onPressed: () => ref.read(userSearchControllerProvider.notifier).retry(),
          child: const Text('Reintentar'),
        ),
      );
    }

    if (state.isQueryTooShort) {
      return const _CenteredMessage(
        icon: Icons.person_search_outlined,
        message: 'Escribe al menos $kUserSearchMinQueryLength caracteres para '
            'buscar un usuario.',
      );
    }

    if (state.isSearching && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.results.isEmpty) {
      return _CenteredMessage(
        icon: Icons.search_off,
        message: 'No hay ningún usuario que coincida con "${state.query}".',
      );
    }

    return Column(
      children: [
        // Refresco sobre resultados ya visibles: una barra fina en vez de
        // vaciar la lista en cada pulsación.
        SizedBox(
          height: 4,
          child: state.isSearching
              ? const LinearProgressIndicator(minHeight: 4)
              : null,
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.results.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.results.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final user = state.results[index];
              return ListTile(
                // CU-20: el nombre y, al lado, su foto de perfil.
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user.displayName),
                // Los bloqueados salen en la lista para poder entrar y
                // deshacerlo, pero marcados y sin más datos que el nombre.
                subtitle: user.isBlocked
                    ? Text(
                        'Bloqueado',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : user.cityName == null
                    ? null
                    : Text(
                        user.cityName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                onTap: () => widget.onUserTap(user),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Estados sin lista (inicial, sin resultados, error): icono, texto y, si
/// procede, una acción.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
