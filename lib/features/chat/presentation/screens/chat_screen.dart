import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../moderation/presentation/controllers/report_controller.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../domain/message_visibility.dart';
import '../../domain/models/message.dart';
import '../controllers/chat_controllers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // En escritorio el panel de detalle reutiliza la pantalla al cambiar de
    // conversación, sin volver a construirla.
    if (oldWidget.conversationId != widget.conversationId) {
      _markRead();
    }
  }

  /// Con el chat abierto, lo que llega ya está leído. Se llama al entrar y con
  /// cada mensaje nuevo, para que el badge no suba mientras estás mirándolo.
  void _markRead() {
    ref
        .read(markConversationReadControllerProvider.notifier)
        .markRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _messageController.text;
    final sent = await ref
        .read(sendMessageControllerProvider.notifier)
        .send(conversationId: widget.conversationId, content: content);
    if (sent && mounted) {
      _messageController.clear();
    }
  }

  /// CU-11 desde un chat existente: reportar al otro participante.
  Future<void> _reportOtherUser(String otherUserId) async {
    final reasons = await showReportDialog(context);
    if (reasons == null || !mounted) return;

    final done = await ref
        .read(reportUserControllerProvider.notifier)
        .reportAndBlock(reportedUserId: otherUserId, reasons: reasons);
    if (!done || !mounted) return;
    ref.invalidate(conversationsProvider);
    ref.invalidate(feedControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario reportado y bloqueado.')),
    );
  }

  // --- NUEVAS FUNCIONES PARA EDITAR Y BORRAR ---

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Seguro que quieres borrar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await ref
        .read(messageActionsControllerProvider.notifier)
        .deleteMessage(messageId);
  }

  Future<void> _editMessage(Message message) async {
    final editController = TextEditingController(text: message.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(editController.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newContent == null ||
        newContent.trim().isEmpty ||
        newContent == message.content ||
        !mounted) {
      return;
    }
    await ref
        .read(messageActionsControllerProvider.notifier)
        .updateMessage(message.id, newContent);
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar mensaje'),
              onTap: () {
                Navigator.of(context).pop();
                _editMessage(message);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Eliminar mensaje',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );
    final currentUserId = ref.watch(currentUserIdProvider);
    final isSending = ref.watch(sendMessageControllerProvider).isLoading;
    final theme = Theme.of(context);

    // Escuchamos posibles errores en las acciones del mensaje
    ref.listen(messageActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    ref.listen(sendMessageControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
    ref.listen(reportUserControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    // Con el chat abierto, lo que llegue se marca leído en el momento: si no,
    // el badge subiría mientras lo estás mirando.
    ref.listen(messagesStreamProvider(widget.conversationId), (previous, next) {
      final before = previous?.value?.length ?? 0;
      final now = next.value?.length ?? 0;
      if (now > before) _markRead();
    });

    final otherUser = conversationAsync.value?.otherUser;
    final blocks =
        ref.watch(myBlocksProvider).value ?? const <String, DateTime>{};
    final blockedAt = otherUser == null ? null : blocks[otherUser.id];
    final isBlocked = blockedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          loading: () => const Text('Chat'),
          error: (_, _) => const Text('Chat'),
          data: (conversation) => Text(conversation.otherUser.displayName),
        ),
        actions: [
          // CU-11, paso 1-2: botón de opciones en un chat existente.
          if (otherUser != null && !isBlocked)
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (_) => _reportOtherUser(otherUser.id),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('Reportar')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(
                  child: Text('No se pudieron cargar los mensajes.'),
                ),
                data: (allMessages) {
                  // Efecto del bloqueo (CU-11): si te sigue escribiendo, no lo
                  // ves. La regla vive en el dominio, no aquí.
                  final messages = visibleMessages(
                    allMessages,
                    currentUserId: currentUserId,
                    blockedAt: blockedAt,
                  );

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Escribe el primer mensaje.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMine = message.senderId == currentUserId;

                      // NUEVO: Detectamos si es un mensaje "eliminado"
                      final isDeleted =
                          message.content ==
                          '🚫 Este mensaje ha sido eliminado';

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          // NUEVO: Bloqueamos las opciones si el mensaje está borrado
                          onLongPress: (isMine && !isDeleted)
                              ? () => _showMessageOptions(message)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.content,
                              // NUEVO: Estilo atenuado para el texto de eliminado
                              style: isDeleted
                                  ? TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (isBlocked)
              // Efecto del bloqueo (CU-11): no se puede chatear con él.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  'Has bloqueado a este usuario. No puedes enviarle mensajes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: isSending ? null : _send,
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      tooltip: 'Enviar',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
