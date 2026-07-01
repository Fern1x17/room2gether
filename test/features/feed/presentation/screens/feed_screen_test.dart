import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomie/features/feed/data/feed_repository.dart';
import 'package:roomie/features/feed/data/recent_searches_repository.dart';
import 'package:roomie/features/feed/presentation/screens/feed_screen.dart';
import 'package:roomie/features/profile/data/profile_repository.dart';

import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_feed_repository.dart';
import '../../fakes/fake_recent_searches_repository.dart';

Widget _wrap({FakeFeedRepository? feedRepository}) {
  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(
        feedRepository ?? FakeFeedRepository(listings: const []),
      ),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      recentSearchesRepositoryProvider.overrideWithValue(FakeRecentSearchesRepository()),
    ],
    child: const MaterialApp(home: FeedScreen()),
  );
}

void main() {
  group('FeedScreen', () {
    testWidgets('muestra el mensaje de vacío si no hay publicaciones', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('No hay publicaciones que coincidan con tu búsqueda.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra las publicaciones cuando las hay', (tester) async {
      await tester.pumpWidget(
        _wrap(
          feedRepository: FakeFeedRepository(
            listings: [fakeListing(title: 'Habitación en el centro')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('el botón de buscar abre el panel de filtros', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar publicaciones'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Ciudad'), findsOneWidget);
    });
  });
}
