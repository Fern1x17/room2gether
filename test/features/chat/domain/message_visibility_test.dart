import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/chat/domain/message_visibility.dart';
import 'package:room2gether/features/chat/domain/models/message.dart';

Message _message({
  required String id,
  required String senderId,
  required DateTime createdAt,
}) {
  return Message(
    id: id,
    conversationId: 'conv-1',
    senderId: senderId,
    content: 'Hola',
    createdAt: createdAt,
  );
}

void main() {
  final blockedAt = DateTime(2026, 7, 24, 12);
  final antes = _message(
    id: 'antes',
    senderId: 'user-2',
    createdAt: blockedAt.subtract(const Duration(hours: 1)),
  );
  final despues = _message(
    id: 'despues',
    senderId: 'user-2',
    createdAt: blockedAt.add(const Duration(hours: 1)),
  );
  final mioDespues = _message(
    id: 'mio',
    senderId: 'user-1',
    createdAt: blockedAt.add(const Duration(hours: 2)),
  );

  group('visibleMessages', () {
    test('sin bloqueo se ven todos', () {
      final result = visibleMessages(
        [antes, despues],
        currentUserId: 'user-1',
        blockedAt: null,
      );

      expect(result, [antes, despues]);
    });

    test('con bloqueo se ocultan los suyos posteriores al bloqueo', () {
      final result = visibleMessages(
        [antes, despues],
        currentUserId: 'user-1',
        blockedAt: blockedAt,
      );

      expect(result, [antes]);
    });

    test('la conversación anterior al bloqueo se conserva', () {
      final result = visibleMessages(
        [antes],
        currentUserId: 'user-1',
        blockedAt: blockedAt,
      );

      expect(result, [antes]);
    });

    test('los mensajes propios nunca se ocultan', () {
      final result = visibleMessages(
        [despues, mioDespues],
        currentUserId: 'user-1',
        blockedAt: blockedAt,
      );

      expect(result, [mioDespues]);
    });
  });
}
