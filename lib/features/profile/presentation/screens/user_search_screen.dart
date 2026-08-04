import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/user_search_controller.dart';
import '../widgets/user_search_results.dart';

/// Buscador de usuarios (CU-20): se escribe un nombre y la lista se va
/// actualizando conforme se teclea.
class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo para saber si mostrar la "x" de limpiar.
    final hasText = ref.watch(
      userSearchControllerProvider.select((state) => state.query.isNotEmpty),
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nombre de usuario',
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _queryController.clear();
                      ref
                          .read(userSearchControllerProvider.notifier)
                          .updateQuery('');
                    },
                  )
                : null,
          ),
          onChanged: (value) =>
              ref.read(userSearchControllerProvider.notifier).updateQuery(value),
        ),
      ),
      body: SafeArea(
        child: UserSearchResults(
          // CU-19: al pulsar un resultado se abre su perfil.
          onUserTap: (user) => context.push('/users/${user.id}'),
        ),
      ),
    );
  }
}
