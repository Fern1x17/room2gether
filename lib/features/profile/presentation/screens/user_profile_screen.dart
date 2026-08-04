import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../chat/presentation/controllers/chat_controllers.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/listing_card.dart';
import '../../../moderation/presentation/controllers/report_controller.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../domain/models/public_profile.dart';
import '../../domain/profile_labels.dart';
import '../controllers/public_profile_controller.dart';

/// Perfil público de otro usuario (CU-19): sus datos públicos, sus
/// publicaciones activas y las acciones de contacto y moderación.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  /// Refresca lo que depende del bloqueo. Mismo patrón que
  /// `BlockedUsersScreen`: cada pantalla refresca los efectos que viven en
  /// otras features, para no acoplar los controladores de moderación.
  void _refreshAfterBlockChange(WidgetRef ref) {
    ref.invalidate(publicProfileProvider(userId));
    ref.invalidate(userListingsProvider(userId));
    ref.invalidate(feedControllerProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(unreadCountsProvider);
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: const Text(
          '¿Seguro que quieres bloquear a este usuario? Dejarás de ver sus '
          'publicaciones y no podréis escribiros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(blockUserControllerProvider.notifier)
        .block(userId);
    if (ok) _refreshAfterBlockChange(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Usuario bloqueado.' : 'No se pudo bloquear. Inténtalo de nuevo.',
        ),
      ),
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: const Text(
          '¿Seguro que quieres desbloquearlo? Volverás a ver sus '
          'publicaciones y podréis escribiros de nuevo.',
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
        .unblock(userId);
    if (ok) _refreshAfterBlockChange(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Usuario desbloqueado.'
              : 'No se pudo desbloquear. Inténtalo de nuevo.',
        ),
      ),
    );
  }

  /// CU-11 desde el perfil: reportar lleva bloqueo, igual que desde una
  /// publicación o un chat. Con [alreadyBlocked] el bloqueo ya existe y la
  /// acción solo añade el reporte; el aviso lo dice tal cual para no anunciar
  /// un cambio que no ocurre.
  Future<void> _report(
    BuildContext context,
    WidgetRef ref, {
    required bool alreadyBlocked,
  }) async {
    final reasons = await showReportDialog(context);
    if (reasons == null || !context.mounted) return;

    final done = await ref
        .read(reportUserControllerProvider.notifier)
        .reportAndBlock(reportedUserId: userId, reasons: reasons);
    if (done) _refreshAfterBlockChange(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch ((done, alreadyBlocked)) {
            (false, _) => 'No se pudo enviar el reporte. Inténtalo de nuevo.',
            (true, true) => 'Usuario reportado.',
            (true, false) => 'Usuario reportado y bloqueado.',
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage(BuildContext context, WidgetRef ref) async {
    final conversation = await ref
        .read(openConversationControllerProvider.notifier)
        .open(otherUserId: userId);
    if (conversation != null && context.mounted) {
      // Tiene que ser `go`. Con `push` se apilaría la página del shell encima
      // de esta ruta raíz cuando ya está debajo en la pila, y el Navigator
      // aborta por claves de página duplicadas.
      //
      // El `extra` le dice al chat que su flecha debe devolver aquí, y no a la
      // lista de conversaciones, que en este recorrido no se ha visto.
      context.go('/chats/${conversation.id}', extra: '/users/$userId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isMe = currentUserId != null && currentUserId == userId;

    ref.listen(openConversationControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    // `valueOrNull` y no `value`: este último RELANZA el error cuando la carga
    // ha fallado, y aquí solo queremos saber si hay perfil para decidir si
    // pintar el menú de opciones. El estado de error lo pinta el `when`.
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        // Flecha explícita en vez de la automática. Al volver del chat se
        // llega aquí con `go`, que reemplaza la pila: no queda nada que
        // desapilar y la flecha automática desaparecería. Con el recambio al
        // feed, el perfil nunca se queda sin salida.
        leading: const AppBackButton(),
        title: const Text('Perfil'),
        actions: [
          if (!isMe && profile != null)
            PopupMenuButton<String>(
              tooltip: 'Opciones del usuario',
              onSelected: (value) => switch (value) {
                'block' => _block(context, ref),
                'unblock' => _unblock(context, ref),
                _ => _report(
                  context,
                  ref,
                  alreadyBlocked: profile.isBlockedByMe,
                ),
              },
              itemBuilder: (context) => profile.isBlockedByMe
                  // Ya está bloqueado, así que reportar solo añade el reporte:
                  // la etiqueta no promete un bloqueo que ya existe.
                  ? const [
                      PopupMenuItem(
                        value: 'unblock',
                        child: Text('Desbloquear'),
                      ),
                      PopupMenuItem(value: 'report', child: Text('Reportar')),
                    ]
                  : const [
                      PopupMenuItem(value: 'block', child: Text('Bloquear')),
                      PopupMenuItem(
                        value: 'report',
                        child: Text('Reportar y bloquear'),
                      ),
                    ],
            ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudo cargar el perfil.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(publicProfileProvider(userId)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const _CenteredNotice(
                icon: Icons.person_off_outlined,
                title: 'Usuario no encontrado',
                message: 'Puede que haya eliminado su cuenta.',
              );
            }
            if (!profile.isVisible) {
              return _BlockedNotice(
                profile: profile,
                onUnblock: () => _unblock(context, ref),
              );
            }
            return _ProfileContent(
              profile: profile,
              isMe: isMe,
              onSendMessage: () => _sendMessage(context, ref),
            );
          },
        ),
      ),
    );
  }
}

/// Perfil visible: datos públicos + publicaciones activas + contacto.
class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.isMe,
    required this.onSendMessage,
  });

  final PublicProfile profile;
  final bool isMe;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOpeningChat = ref
        .watch(openConversationControllerProvider)
        .isLoading;
    final budget = profile.budgetLabel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.displayNameLabel,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (profile.cityName != null && profile.cityName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile.cityName!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Sobre mí', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          if (budget != null) ...[
            const SizedBox(height: 24),
            Text('Presupuesto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(budget, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (profile.isSmoker != null)
                Chip(
                  avatar: Icon(
                    profile.isSmoker! ? Icons.smoking_rooms : Icons.smoke_free,
                    size: 18,
                  ),
                  label: Text(profile.isSmoker! ? 'Fumador' : 'No fumador'),
                ),
              if (profile.hasPets != null)
                Chip(
                  avatar: const Icon(Icons.pets, size: 18),
                  label: Text(
                    profile.hasPets! ? 'Tiene mascotas' : 'Sin mascotas',
                  ),
                ),
              if (profile.cleanlinessLevel != null)
                Chip(
                  avatar: const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: Text('Limpieza ${profile.cleanlinessLevel} de 5'),
                ),
              if (kScheduleLabels[profile.schedule] != null)
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(kScheduleLabels[profile.schedule]!),
                ),
            ],
          ),
          if (!isMe) ...[
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isOpeningChat ? null : onSendMessage,
                icon: isOpeningChat
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: const Text('Enviar mensaje'),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text('Publicaciones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _UserListings(userId: profile.id),
        ],
      ),
    );
  }
}

/// Publicaciones activas del usuario, dentro de su perfil.
class _UserListings extends ConsumerWidget {
  const _UserListings({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(userListingsProvider(userId));

    return listingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No se pudieron cargar sus publicaciones.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Este usuario no tiene publicaciones activas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final listing in listings)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListingCard(
                  listing: listing,
                  // `go` y no `push`, por lo mismo que el chat: el detalle
                  // vive en una rama del shell y esto es una ruta raíz. El
                  // origen viaja en `extra` para que la flecha vuelva aquí.
                  onTap: () => context.go(
                    '/listings/${listing.id}',
                    extra: '/users/$userId',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Perfil oculto por un bloqueo, en cualquiera de los dos sentidos.
/// Perfil oculto por un bloqueo. Los dos sentidos NO se tratan igual, a
/// propósito: el bloqueo propio se puede deshacer desde aquí y por eso enseña
/// el nombre y el botón; el del otro no es decisión mía y no sale nada.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({
    required this.profile,
    required this.onUnblock,
  });

  final PublicProfile profile;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!profile.isBlockedByMe) {
      return const _CenteredNotice(
        icon: Icons.block,
        title: 'Usuario bloqueado',
        message: 'No puedes ver los datos de este perfil.',
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            // Único dato que llega con bloqueo propio: sin el nombre no se
            // podría decir a quién se está desbloqueando.
            Text(
              profile.displayNameLabel,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Has bloqueado a este usuario, así que no puedes ver sus datos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onUnblock,
                icon: const Icon(Icons.lock_open),
                label: const Text('Desbloquear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredNotice extends StatelessWidget {
  const _CenteredNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
