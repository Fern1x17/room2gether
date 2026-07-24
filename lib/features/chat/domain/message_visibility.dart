import 'models/message.dart';

/// Mensajes que se muestran en un chat, aplicando el efecto del bloqueo.
///
/// Si has bloqueado a la otra persona (CU-11), lo que te escriba **a partir de
/// ese momento** no lo ves. Se filtra por fecha y no de golpe a propósito:
///
/// - la conversación anterior al bloqueo es tuya y sigue teniendo sentido, como
///   en cualquier app de mensajería;
/// - y así desbloquear no tiene que "restaurar" nada, solo deja de filtrar.
///
/// Los mensajes propios nunca se ocultan: son tuyos, los escribiste tú.
List<Message> visibleMessages(
  List<Message> messages, {
  required String? currentUserId,
  DateTime? blockedAt,
}) {
  if (blockedAt == null) return messages;
  return messages
      .where(
        (message) =>
            message.senderId == currentUserId ||
            message.createdAt.isBefore(blockedAt),
      )
      .toList();
}
