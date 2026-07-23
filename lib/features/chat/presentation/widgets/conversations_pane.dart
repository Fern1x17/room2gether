import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'conversations_list_view.dart';

/// Columna izquierda de la sección Chats en escritorio: lista persistente de
/// conversaciones. El chat se abre en el panel derecho navegando a
/// /chats/:id (misma rama), de modo que la URL sigue siendo compartible y el
/// patrón es idéntico al del feed (lista | detalle).
class ConversationsListPane extends ConsumerWidget {
  const ConversationsListPane({super.key, required this.currentUri});

  /// URI actual del router; la pasa el DesktopShell en cada navegación.
  final Uri currentUri;

  String? get _selectedConversationId {
    final segments = currentUri.pathSegments;
    if (segments.length == 2 && segments.first == 'chats') {
      return segments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = _selectedConversationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Chats', style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ConversationsListView(
            selectedConversationId: selectedId,
            onConversationTap: (conversation) {
              final target = '/chats/${conversation.id}';
              // Con un chat ya abierto se sustituye en vez de apilar, para que
              // la pila del panel no crezca sin límite (igual que el feed).
              if (selectedId != null) {
                context.pushReplacement(target);
              } else {
                context.push(target);
              }
            },
          ),
        ),
      ],
    );
  }
}
