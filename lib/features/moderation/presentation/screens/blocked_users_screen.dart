import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/controllers/chat_controllers.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../domain/models/blocked_user.dart';
import '../controllers/report_controller.dart';

/// Lista de usuarios bloqueados con la acción de desbloquear (CU-11).
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: Text(
          '¿Seguro que quieres desbloquear a ${user.displayName}? Volverás a '
          'ver sus publicaciones y podréis escribiros de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(unblockUserControllerProvider.notifier)
        .unblock(user.id);
    if (ok) {
      // Efectos del bloqueo que viven en otras features (mismo patrón que el
      // reporte en ChatScreen): el feed vuelve a incluir sus publicaciones,
      // el chat deja de ocultar sus mensajes y su contador vuelve a sumar.
      ref.invalidate(feedControllerProvider);
      ref.invalidate(conversationsProvider);
      ref.invalidate(unreadCountsProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${user.displayName} desbloqueado.'
              : 'No se pudo desbloquear. Inténtalo de nuevo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios bloqueados')),
      body: SafeArea(
        child: blockedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los usuarios bloqueados.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(blockedUsersProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No has bloqueado a nadie.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('Bloqueado el ${_formatDate(user.blockedAt)}'),
                  trailing: OutlinedButton(
                    onPressed: () => _confirmUnblock(context, ref, user),
                    child: const Text('Desbloquear'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Fecha en español, ej. "12 de julio de 2026". Se muestra en la zona horaria
/// local del usuario.
String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} de ${_months[local.month - 1]} de ${local.year}';
}
