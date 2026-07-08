import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../moderation/presentation/controllers/report_controller.dart';
import '../controllers/chat_controllers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    // Postcondición CU-11: el reportado aparece como bloqueado para quien
    // hizo el reporte.
    final blockedIds =
        ref.watch(blockedUserIdsProvider).value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: conversationsAsync.when(
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
                onTap: () => context.push('/chats/${conversation.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
