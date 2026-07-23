import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/adaptive_shell.dart';
import '../../../../core/layout/breakpoints.dart';
import '../widgets/conversations_list_view.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // En escritorio la lista de conversaciones la pinta el DesktopShell como
    // columna persistente; la página /chats queda como el panel de detalle sin
    // selección. Misma regla de ancho que el AdaptiveShell (igual que el feed).
    final desktopSupported = ref.watch(desktopLayoutSupportedProvider);
    final isDesktopLayout =
        desktopSupported &&
        MediaQuery.sizeOf(context).width >= kDesktopMinWidth;
    if (isDesktopLayout) {
      return const _ConversationDetailPlaceholder();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ConversationsListView(
        onConversationTap: (conversation) =>
            context.push('/chats/${conversation.id}'),
      ),
    );
  }
}

/// Estado vacío del panel de chat en escritorio.
class _ConversationDetailPlaceholder extends StatelessWidget {
  const _ConversationDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona una conversación para ver el chat',
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
