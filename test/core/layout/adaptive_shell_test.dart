import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/layout/adaptive_shell.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/router/app_router.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/feed/data/recent_searches_repository.dart';
import 'package:room2gether/features/listing/data/listing_repository.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';

import '../../features/chat/fakes/fake_chat_repository.dart';
import '../../features/feed/fakes/fake_feed_repository.dart';
import '../../features/feed/fakes/fake_recent_searches_repository.dart';
import '../../features/listing/fakes/fake_listing_repository.dart';
import '../../features/moderation/fakes/fake_moderation_repository.dart';
import '../../features/profile/fakes/fake_profile_repository.dart';
import '../cities/fake_cities.dart';
import '../places/fake_places.dart';

Widget _wrapApp({bool desktopSupported = false}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      feedRepositoryProvider.overrideWithValue(
        FakeFeedRepository(
          listings: [fakeListing(title: 'Habitación en el centro')],
        ),
      ),
      listingRepositoryProvider.overrideWithValue(FakeListingRepository()),
      chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      recentSearchesRepositoryProvider.overrideWithValue(
        FakeRecentSearchesRepository(),
      ),
      moderationRepositoryProvider.overrideWithValue(
        FakeModerationRepository(),
      ),
      citiesRepositoryProvider.overrideWithValue(FakeCitiesRepository()),
      placesServiceProvider.overrideWithValue(FakePlacesService()),
      // En la VM de tests kIsWeb es false; se sobrescribe para simular web.
      if (desktopSupported)
        desktopLayoutSupportedProvider.overrideWithValue(true),
    ],
    child: MaterialApp.router(
      routerConfig: buildAppRouter(initialLocation: '/feed'),
    ),
  );
}

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('AdaptiveShell', () {
    testWidgets('en ancho de móvil muestra la barra inferior', (tester) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets(
      'en ancho de escritorio sin soporte web (Android) sigue en móvil',
      (tester) async {
        _setViewSize(tester, const Size(1280, 800));
        await tester.pumpWidget(_wrapApp());
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets('en web ancha muestra rail, filtros y panel de detalle', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(_wrapApp(desktopSupported: true));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // Panel de filtros persistente y placeholder del detalle.
      expect(find.text('Filtros'), findsOneWidget);
      expect(
        find.text('Selecciona una publicación para ver el detalle'),
        findsOneWidget,
      );
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('en web ancha, tocar una tarjeta abre el detalle en el panel', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(_wrapApp(desktopSupported: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();

      // La lista sigue visible (master-detail) y el placeholder desaparece.
      expect(
        find.text('Selecciona una publicación para ver el detalle'),
        findsNothing,
      );
      // El título aparece en la tarjeta de la lista y en el detalle.
      expect(find.text('Habitación en el centro'), findsNWidgets(2));
      expect(find.text('Publicación'), findsOneWidget);
    });

    testWidgets('en web estrecha (móvil web) se usa la barra inferior', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(desktopSupported: true));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('la pestaña Chats navega a la lista de conversaciones', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      expect(
        find.text('No tienes ningún chat todavía. Contacta desde una publicación.'),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
