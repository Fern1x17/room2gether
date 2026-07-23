import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/layout/adaptive_shell.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/router/app_router.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/chat/data/chat_repository.dart';
import 'package:room2gether/features/chat/domain/models/conversation.dart';
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

Widget _wrapApp({
  bool desktopSupported = false,
  List<Conversation> conversations = const [],
  String listingOwnerId = 'user-1',
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      feedRepositoryProvider.overrideWithValue(
        FakeFeedRepository(
          listings: [
            fakeListing(
              title: 'Habitación en el centro',
              ownerId: listingOwnerId,
            ),
          ],
        ),
      ),
      listingRepositoryProvider.overrideWithValue(FakeListingRepository()),
      chatRepositoryProvider.overrideWithValue(
        FakeChatRepository(conversations: [...conversations]),
      ),
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
        find.text(
          'No tienes ningún chat todavía. Contacta desde una publicación.',
        ),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets(
      'en web ancha, la sección Chats muestra la lista y el placeholder',
      (tester) async {
        _setViewSize(tester, const Size(1280, 800));
        await tester.pumpWidget(
          _wrapApp(
            desktopSupported: true,
            conversations: [fakeConversation(otherName: 'Ana')],
          ),
        );
        await tester.pumpAndSettle();

        // Cambiar a la sección Chats desde el rail.
        await tester.tap(find.text('Chats'));
        await tester.pumpAndSettle();

        // Master-detail: lista de conversaciones persistente + panel vacío,
        // con el rail siempre visible (no barra inferior).
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Ana'), findsOneWidget);
        expect(
          find.text('Selecciona una conversación para ver el chat'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'en web ancha, tocar una conversación abre el chat en el panel',
      (tester) async {
        _setViewSize(tester, const Size(1280, 800));
        await tester.pumpWidget(
          _wrapApp(
            desktopSupported: true,
            conversations: [fakeConversation(otherName: 'Ana')],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chats'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ana'));
        // pump con duración fija (no pumpAndSettle): el chat muestra un spinner
        // mientras el stream de mensajes no emite y nunca "asienta". 1 s cubre
        // la transición de navegación del panel.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // La lista sigue visible (master-detail) y el placeholder desaparece;
        // el nombre aparece en la lista y en la cabecera del chat.
        expect(
          find.text('Selecciona una conversación para ver el chat'),
          findsNothing,
        );
        expect(find.text('Ana'), findsNWidgets(2));
        expect(find.byType(NavigationRail), findsOneWidget);
      },
    );

    testWidgets(
      'en web ancha, "Enviar mensaje" desde una publicación abre el chat en '
      'la sección Chats',
      (tester) async {
        _setViewSize(tester, const Size(1280, 800));
        await tester.pumpWidget(
          _wrapApp(desktopSupported: true, listingOwnerId: 'user-2'),
        );
        await tester.pumpAndSettle();

        // Abrir el detalle de la publicación ajena en el panel de Buscar.
        await tester.tap(find.text('Habitación en el centro'));
        await tester.pumpAndSettle();

        // Contactar: cruza de la rama Buscar a la rama Chats (context.go).
        await tester.tap(find.text('Enviar mensaje'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Se abre el chat como panel dentro de la sección Chats (rail visible).
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Escribe un mensaje…'), findsOneWidget);
        // La lista de conversaciones persistente ya incluye la nueva.
        expect(find.text('Ana'), findsWidgets);
      },
    );
  });
}
