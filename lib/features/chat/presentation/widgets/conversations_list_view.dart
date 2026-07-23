import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../moderation/presentation/controllers/report_controller.dart';
import '../../domain/models/conversation.dart';
import '../controllers/chat_controllers.dart';

/// Lista de conversaciones con sus estados de carga/error/vacío. Widget de
/// contenido compartido: en móvil ocupa la pantalla "Chats" y en escritorio
/// es la columna izquierda del master-detail (el panel del chat va a la
/// derecha), igual que [ListingListView] en el feed.
class ConversationsListView extends ConsumerWidget {
  const ConversationsListView({
    super.key,
    required this.onConversationTap,
    this.selectedConversationId,
  });

  final ValueChanged<Conversation> onConversationTap;

  /// Conversación resaltada (la abierta en el panel de detalle de escritorio).
  final String? selectedConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    // Postcondición CU-11: el reportado aparece como bloqueado para quien
    // hizo el reporte.
    final blockedIds =
        ref.watch(blockedUserIdsProvider).value ?? const <String>{};

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudieron cargar tus chats.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No tienes ningún chat todavía. Contacta desde una publicación.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final other = conversation.otherUser;
            return ListTile(
              selected: conversation.id == selectedConversationId,
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              leading: CircleAvatar(
                backgroundImage: other.avatarUrl != null
                    ? NetworkImage(other.avatarUrl!)
                    : null,
                child: other.avatarUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(other.displayName),
              trailing: blockedIds.contains(other.id)
                  ? const Chip(
                      label: Text('Bloqueado'),
                      visualDensity: VisualDensity.compact,
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => onConversationTap(conversation),
            );
          },
        );
      },
    );
  }
}
