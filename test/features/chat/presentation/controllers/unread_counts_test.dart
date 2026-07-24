import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/presentation/controllers/chat_controllers.dart';

import '../../fakes/fake_chat_repository.dart';

/// Espera a que [condition] se cumpla. La cadena "señal → nueva consulta →
/// nueva emisión" atraviesa varios turnos del event loop, así que un solo
/// `Future.delayed(Duration.zero)` no basta y fijar una espera larga haría el
/// test lento y frágil.
Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('La condición no se cumplió en $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

ProviderContainer _container(FakeChatRepository fakeRepo) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      chatRepositoryProvider.overrideWithValue(fakeRepo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('unreadCountsProvider', () {
    test('emite el conteo inicial', () async {
      final fakeRepo = FakeChatRepository()
        ..unreadCounts = {'conv-1': 2, 'conv-2': 5};
      final container = _container(fakeRepo);

      final counts = await container.read(unreadCountsProvider.future);

      expect(counts, {'conv-1': 2, 'conv-2': 5});
    });

    test('recalcula cuando Realtime avisa de un cambio', () async {
      final fakeRepo = FakeChatRepository()..unreadCounts = {'conv-1': 1};
      final container = _container(fakeRepo);

      await container.read(unreadCountsProvider.future);
      expect(fakeRepo.unreadFetches, 1);

      // El canal es broadcast: una señal emitida antes de que el provider se
      // suscriba se pierde, así que hay que esperar a que esté escuchando.
      await _waitFor(() => fakeRepo.inboxController.hasListener);

      // Llega un mensaje nuevo: el canal solo emite la señal.
      fakeRepo.unreadCounts = {'conv-1': 2};
      fakeRepo.inboxController.add(null);
      await _waitFor(() => fakeRepo.unreadFetches == 2);

      expect(container.read(unreadCountsProvider).value, {'conv-1': 2});
    });
  });

  group('totalUnreadProvider', () {
    test('suma todas las conversaciones', () async {
      final fakeRepo = FakeChatRepository()
        ..unreadCounts = {'conv-1': 2, 'conv-2': 5};
      final container = _container(fakeRepo);

      await container.read(unreadCountsProvider.future);

      expect(container.read(totalUnreadProvider), 7);
    });

    test('vale 0 mientras el conteo aún no ha llegado', () {
      final container = _container(FakeChatRepository());

      expect(container.read(totalUnreadProvider), 0);
    });
  });

  group('formatUnreadCount', () {
    test('muestra el número exacto hasta el tope', () {
      expect(formatUnreadCount(1), '1');
      expect(formatUnreadCount(kUnreadBadgeMax), '99');
    });

    test('corta en 99+ por encima del tope', () {
      expect(formatUnreadCount(kUnreadBadgeMax + 1), '99+');
      expect(formatUnreadCount(347), '99+');
    });
  });

  group('MarkConversationReadController', () {
    test('marca la conversación como leída', () async {
      final fakeRepo = FakeChatRepository()..unreadCounts = {'conv-1': 3};
      final container = _container(fakeRepo);

      await container
          .read(markConversationReadControllerProvider.notifier)
          .markRead('conv-1');

      expect(fakeRepo.readConversationIds, ['conv-1']);
    });

    test('un fallo al marcar no rompe nada', () async {
      final container = _container(_FailingMarkReadRepository());

      // No debe lanzar: marcar como leído es un efecto secundario.
      await container
          .read(markConversationReadControllerProvider.notifier)
          .markRead('conv-1');
    });
  });
}

class _FailingMarkReadRepository extends FakeChatRepository {
  @override
  Future<void> markConversationRead(String conversationId) async {
    throw Exception('sin conexión');
  }
}
