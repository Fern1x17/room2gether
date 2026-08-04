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
import 'package:room2gether/features/profile/data/public_profile_repository.dart';

import '../../features/chat/fakes/fake_chat_repository.dart';
import '../../features/feed/fakes/fake_feed_repository.dart';
import '../../features/feed/fakes/fake_recent_searches_repository.dart';
import '../../features/listing/fakes/fake_listing_repository.dart';
import '../../features/moderation/fakes/fake_moderation_repository.dart';
import '../../features/profile/fakes/fake_profile_repository.dart';
import '../../features/profile/fakes/fake_public_profile_repository.dart';
import '../cities/fake_cities.dart';
import '../places/fake_places.dart';

Widget _wrapApp({
  bool desktopSupported = false,
  List<Conversation> conversations = const [],
  String listingOwnerId = 'user-1',
  Map<String, int> unreadCounts = const {},
  Object? unreadCountsError,
  String initialLocation = '/feed',
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
        FakeChatRepository(
          conversations: [...conversations],
          unreadCountsError: unreadCountsError,
        )..unreadCounts = unreadCounts,
      ),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      publicProfileRepositoryProvider.overrideWithValue(
        FakePublicProfileRepository(profile: fakePublicProfile(id: 'user-2')),
      ),
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
      routerConfig: buildAppRouter(initialLocation: initialLocation),
    ),
  );
}

/// El icono de la sección siempre monta un [Badge]; lo que cambia es si
/// enseña el número o no.
final _visibleBadge = find.byWidgetPredicate(
  (widget) => widget is Badge && widget.isLabelVisible,
);

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

    // El perfil es el destino al que se llega tras confirmar el correo. Antes
    // se entraba por una ruta raíz (`/onboarding`) que quedaba fuera del shell
    // y por tanto sin barra de navegación.
    testWidgets('el perfil también lleva barra inferior en móvil', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(initialLocation: '/profile'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Tu perfil'), findsOneWidget);
    });

    testWidgets('el perfil en web ancha lleva rail, no barra', (tester) async {
      _setViewSize(tester, const Size(1400, 900));
      await tester.pumpWidget(
        _wrapApp(desktopSupported: true, initialLocation: '/profile'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
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

    // Los dos disparadores, uno en cada forma. Se buscan por tooltip y no por
    // icono: es lo que distingue su significado, no el glifo.
    testWidgets('en móvil: lupa al buscador y hamburguesa a los filtros', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Buscar usuarios'), findsOneWidget);
      expect(find.byTooltip('Filtrar publicaciones'), findsOneWidget);
    });

    testWidgets('en web ancha: lupa en la cabecera y ninguna hamburguesa', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(_wrapApp(desktopSupported: true));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Buscar usuarios'), findsOneWidget);
      // Los filtros ya son columna persistente aquí, así que el botón
      // flotante no tiene razón de existir.
      expect(find.byTooltip('Filtrar publicaciones'), findsNothing);
      expect(find.text('Filtros'), findsOneWidget);
    });

    // El botón atrás del sistema: vuelve por las pestañas visitadas en vez de
    // cerrar la app. Se simula con el mismo canal que usa Android.
    Future<void> pressSystemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('atrás vuelve a la pestaña anterior en vez de salir', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shell-destination-1')));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsWidgets);

      await pressSystemBack(tester);

      // De vuelta en el feed, y la app sigue en pie.
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('atrás desanda varias pestañas, una a una', (tester) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shell-destination-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shell-destination-2')));
      await tester.pumpAndSettle();
      expect(find.text('Tu perfil'), findsOneWidget);

      await pressSystemBack(tester);
      expect(find.text('Tu perfil'), findsNothing);

      await pressSystemBack(tester);
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('si la app arranca fuera del feed, atrás lleva al feed', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(initialLocation: '/profile'));
      await tester.pumpAndSettle();
      expect(find.text('Tu perfil'), findsOneWidget);

      await pressSystemBack(tester);

      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    testWidgets('atrás en el feed avisa antes de salir, y no sale a la primera', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      await pressSystemBack(tester);

      expect(find.text('Pulsa otra vez para salir'), findsOneWidget);
      // Sigue en el feed: no se ha cerrado nada.
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    // Entrar en un chat desde fuera de la rama Chats usa `go`. Si /chats/:id
    // fuese hermana de /chats y no subruta, `go` dejaría el chat como única
    // ruta de la rama y no habría flecha de volver.
    testWidgets('entrar en un chat desde una publicación deja flecha atrás', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(listingOwnerId: 'user-2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();
      // El chat no llega a reposo (stream de realtime), así que nada de
      // pumpAndSettle a partir de aquí.
      await tester.tap(find.text('Enviar mensaje'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Estamos en el chat, y se puede volver a la lista de conversaciones.
      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Escribe un mensaje…'), findsNothing);
      expect(find.text('Chats'), findsWidgets);
    });

    // Entrando desde el perfil de alguien, la lista de chats no se ha visto en
    // ningún momento: volver allí sería aterrizar en una pantalla nueva.
    testWidgets('desde el perfil de alguien, atrás en el chat vuelve al perfil', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(listingOwnerId: 'user-2'));
      await tester.pumpAndSettle();

      // Se llega al perfil desde el detalle de una publicación, como en la
      // app: así el perfil tiene su propia flecha antes de entrar al chat.
      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Enviar mensaje'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar mensaje'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Escribe un mensaje…'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // De vuelta en el perfil, no en la lista de conversaciones...
      expect(find.text('Escribe un mensaje…'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Enviar mensaje'), findsOneWidget);

      // ...y el perfil sigue teniendo flecha. Volver del chat se hace con `go`
      // y eso reemplaza la pila, así que no queda nada que desapilar: la
      // flecha tira del recambio al feed en lugar de desaparecer.
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Habitación en el centro'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('desde el perfil, la publicación tiene flecha y vuelve allí', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        _wrapApp(listingOwnerId: 'user-2', initialLocation: '/users/user-2'),
      );
      await tester.pumpAndSettle();

      // Su publicación, al final del perfil: hay que bajar hasta ella.
      await tester.ensureVisible(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();
      expect(find.text('Publicación'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // De vuelta en el perfil, no en el feed.
      expect(find.text('Publicación'), findsNothing);
      expect(find.text('Perfil'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Enviar mensaje'),
        findsOneWidget,
      );
    });

    testWidgets('en escritorio el panel de detalle no gana flecha de volver', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(
        _wrapApp(desktopSupported: true, listingOwnerId: 'user-2'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();

      // El detalle se apila dentro de la rama, así que la flecha ya existía
      // antes de este cambio y debe seguir haciendo lo mismo: volver al
      // placeholder, con la lista siempre visible al lado.
      expect(find.text('Publicación'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Selecciona una publicación para ver el detalle'),
        findsOneWidget,
      );
      expect(find.text('Habitación en el centro'), findsOneWidget);
    });

    // Lo que NO debe hacer: secuestrar el atrás de las pantallas apiladas.
    testWidgets('atrás cierra primero el detalle, sin cambiar de pestaña', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(listingOwnerId: 'user-2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habitación en el centro'));
      await tester.pumpAndSettle();
      // El detalle se apila dentro de la rama, así que la barra inferior sigue
      // ahí; lo que distingue a las dos pantallas es el botón de contactar.
      expect(find.text('Enviar mensaje'), findsOneWidget);

      await pressSystemBack(tester);

      // De vuelta en la lista del feed, no en otra pestaña ni fuera de la app.
      expect(find.text('Enviar mensaje'), findsNothing);
      expect(find.text('Habitación en el centro'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Pulsa otra vez para salir'), findsNothing);
    });

    testWidgets('la flecha de Chats vuelve a la pestaña anterior', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shell-destination-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Volver a la pestaña anterior'));
      await tester.pumpAndSettle();

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

    // El badge se define una sola vez (ShellDestinationIcon) y lo usan la barra
    // y el rail: estos dos tests fijan que aparece en ambas formas.
    testWidgets('el badge de no leídos aparece en la barra inferior', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        _wrapApp(unreadCounts: const {'conv-1': 3, 'conv-2': 4}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('el badge de no leídos aparece en el rail de escritorio', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(
        _wrapApp(
          desktopSupported: true,
          unreadCounts: const {'conv-1': 3, 'conv-2': 4},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('sin mensajes sin leer no se pinta ningún badge', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
    });

    // Regresión: con `.value`, un fallo del conteo se relanzaba en
    // totalUnreadProvider y reventaba el icono, y con él la barra entera. El
    // badge es información secundaria: si no hay número, no se pinta y ya.
    testWidgets('si falla el conteo, la barra sigue en pie y sin badge', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(unreadCountsError: Exception('caída')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(_visibleBadge, findsNothing);
    });

    testWidgets('si falla el conteo, el rail de escritorio sigue en pie', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 800));
      await tester.pumpWidget(
        _wrapApp(desktopSupported: true, unreadCountsError: Exception('caída')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(_visibleBadge, findsNothing);
    });

    testWidgets('el contador se corta en 99+', (tester) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrapApp(unreadCounts: const {'conv-1': 250}));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('la lista de chats muestra el contador de su conversación', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        _wrapApp(
          conversations: [fakeConversation(otherName: 'Ana')],
          unreadCounts: const {'conv-1': 3},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      // El 3 de la conversación y el 3 del badge de la barra.
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('3'), findsNWidgets(2));
    });

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
