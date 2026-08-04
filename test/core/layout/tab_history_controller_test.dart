import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/layout/tab_history_controller.dart';

void main() {
  group('TabHistory', () {
    late ProviderContainer container;
    late TabHistory history;

    setUp(() {
      container = ProviderContainer();
      history = container.read(tabHistoryProvider.notifier);
      addTearDown(container.dispose);
    });

    test('apila las pestañas visitadas', () {
      history.visit(0);
      history.visit(1);
      history.visit(2);

      expect(container.read(tabHistoryProvider), [0, 1, 2]);
    });

    test('repetir la pestaña de arriba no apila', () {
      history.visit(1);
      history.visit(1);

      expect(container.read(tabHistoryProvider), [1]);
    });

    test('goBack desanda el camino paso a paso', () {
      history.visit(0);
      history.visit(1);
      history.visit(2);

      expect(history.goBack(), 1);
      expect(history.goBack(), 0);
      // Ya en la primera: no hay anterior.
      expect(history.goBack(), isNull);
    });

    test('goBack devuelve null si la app arrancó en esta pestaña', () {
      history.visit(1);

      expect(history.goBack(), isNull);
    });

    test('el historial no crece sin fin al alternar entre dos pestañas', () {
      for (var i = 0; i < 100; i++) {
        history.visit(i.isEven ? 0 : 1);
      }

      expect(container.read(tabHistoryProvider).length, lessThanOrEqualTo(20));
    });
  });

  group('goToPreviousTab', () {
    late ProviderContainer container;
    late List<int> branchesVisited;

    setUp(() {
      container = ProviderContainer();
      branchesVisited = [];
      addTearDown(container.dispose);
    });

    /// `goToPreviousTab` pide un `WidgetRef`, pero solo usa `ref.read`.
    bool run({required int currentIndex}) {
      return goToPreviousTab(
        _TestRef(container),
        currentIndex: currentIndex,
        goBranch: branchesVisited.add,
      );
    }

    test('vuelve a la pestaña anterior', () {
      final history = container.read(tabHistoryProvider.notifier)
        ..visit(0)
        ..visit(2);

      expect(run(currentIndex: 2), isTrue);
      expect(branchesVisited, [0]);
      expect(container.read(tabHistoryProvider), [0]);
      expect(history.goBack(), isNull);
    });

    test('sin historial y fuera del feed, redirige al feed', () {
      container.read(tabHistoryProvider.notifier).visit(1);

      expect(run(currentIndex: 1), isTrue);
      expect(branchesVisited, [kFeedTabIndex]);
      expect(container.read(tabHistoryProvider), [kFeedTabIndex]);
    });

    test('en el feed sin historial no hay a dónde ir', () {
      container.read(tabHistoryProvider.notifier).visit(kFeedTabIndex);

      expect(run(currentIndex: kFeedTabIndex), isFalse);
      expect(branchesVisited, isEmpty);
    });
  });
}

/// `WidgetRef` mínimo sobre un contenedor: `goToPreviousTab` solo llama a
/// `read`, así que no hace falta montar un widget para probarlo.
class _TestRef implements WidgetRef {
  _TestRef(this.container);

  final ProviderContainer container;

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Solo se usa read en estos tests.');
}
