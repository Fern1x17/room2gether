import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/feed/data/feed_repository.dart';
import 'package:room2gether/features/moderation/data/moderation_repository.dart';
import 'package:room2gether/features/profile/data/public_profile_repository.dart';
import 'package:room2gether/features/profile/presentation/screens/user_profile_screen.dart';

import '../../../feed/fakes/fake_feed_repository.dart';
import '../../../moderation/fakes/fake_moderation_repository.dart';
import '../../fakes/fake_public_profile_repository.dart';

Widget _wrap({
  required FakePublicProfileRepository profileRepo,
  FakeFeedRepository? feedRepo,
  FakeModerationRepository? moderationRepo,
  String currentUserId = 'user-1',
  String userId = 'user-2',
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(currentUserId),
      publicProfileRepositoryProvider.overrideWithValue(profileRepo),
      feedRepositoryProvider.overrideWithValue(
        feedRepo ?? FakeFeedRepository(listings: const []),
      ),
      moderationRepositoryProvider.overrideWithValue(
        moderationRepo ?? FakeModerationRepository(),
      ),
    ],
    child: MaterialApp(home: UserProfileScreen(userId: userId)),
  );
}

void main() {
  group('UserProfileScreen', () {
    testWidgets('muestra los datos públicos del perfil', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Vigo'), findsOneWidget);
      expect(find.text('Busco piso céntrico'), findsOneWidget);
      expect(find.text('300 € - 500 € al mes'), findsOneWidget);
      // Preferencias de convivencia, con los mismos textos que la pestaña
      // Perfil donde se editan.
      expect(find.text('No fumador'), findsOneWidget);
      expect(find.text('Tiene mascotas'), findsOneWidget);
      expect(find.text('Limpieza 4 de 5'), findsOneWidget);
      expect(find.text('Noctámbulo'), findsOneWidget);
    });

    testWidgets('ofrece enviar mensaje en el perfil de otro usuario', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Enviar mensaje'),
        findsOneWidget,
      );
    });

    testWidgets('en el perfil propio no hay contactar ni menú de opciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(id: 'user-1'),
          ),
          currentUserId: 'user-1',
          userId: 'user-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Enviar mensaje'), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('si lo he bloqueado yo: solo el nombre y desbloquear', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakeBlockedPublicProfile(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El nombre sí, para saber a quién desbloqueas. Sus datos no.
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Vigo'), findsNothing);
      expect(find.text('Busco piso céntrico'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Desbloquear'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Enviar mensaje'), findsNothing);
    });

    testWidgets('si me ha bloqueado él, no se enseña ni el nombre', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakeBlockedPublicProfile(isBlockedByMe: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usuario bloqueado'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Desbloquear'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Enviar mensaje'), findsNothing);
    });

    testWidgets('el botón de desbloquear llama al repositorio', (tester) async {
      final moderationRepo = FakeModerationRepository(
        blockedIds: {'user-2'},
      );
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakeBlockedPublicProfile(),
          ),
          moderationRepo: moderationRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
      await tester.pumpAndSettle();
      // Pide confirmación antes.
      expect(moderationRepo.unblockedIds, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear').last);
      await tester.pumpAndSettle();

      expect(moderationRepo.unblockedIds, contains('user-2'));
    });

    testWidgets('si el bloqueo es mío, el menú ofrece desbloquear y reportar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakeBlockedPublicProfile(isBlockedByMe: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Desbloquear'), findsWidgets);
      // "Reportar" a secas: el bloqueo ya existe, no se promete otro.
      expect(find.text('Reportar'), findsOneWidget);
      expect(find.text('Reportar y bloquear'), findsNothing);
      expect(find.text('Bloquear'), findsNothing);
    });

    testWidgets('si no lo he bloqueado yo, el menú ofrece bloquear y reportar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Bloquear'), findsOneWidget);
      expect(find.text('Reportar y bloquear'), findsOneWidget);
      expect(find.text('Desbloquear'), findsNothing);
    });

    testWidgets('bloquear pide confirmación y llama al repositorio', (
      tester,
    ) async {
      final moderationRepo = FakeModerationRepository();
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(),
          ),
          moderationRepo: moderationRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();

      // Todavía no: hay que confirmar.
      expect(moderationRepo.blockedIds, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
      await tester.pumpAndSettle();

      expect(moderationRepo.blockedIds, contains('user-2'));
    });

    testWidgets('lista las publicaciones activas del usuario', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(
            profile: fakePublicProfile(),
          ),
          feedRepo: FakeFeedRepository(
            listings: [
              fakeListing(
                id: 'l1',
                ownerId: 'user-2',
                title: 'Habitación en el centro',
              ),
              // De otra persona: no debe salir en este perfil.
              fakeListing(id: 'l2', ownerId: 'user-9', title: 'Piso ajeno'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habitación en el centro'), findsOneWidget);
      expect(find.text('Piso ajeno'), findsNothing);
    });

    testWidgets('usuario inexistente muestra su aviso', (tester) async {
      await tester.pumpWidget(
        _wrap(profileRepo: FakePublicProfileRepository(profile: null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usuario no encontrado'), findsOneWidget);
    });

    testWidgets('un fallo de carga permite reintentar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profileRepo: FakePublicProfileRepository(error: Exception('caída')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar el perfil.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
    });
  });
}
