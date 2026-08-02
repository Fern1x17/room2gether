import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/layout/breakpoints.dart';
import 'package:room2gether/core/router/app_router.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/listing/data/listing_repository.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';
import 'package:room2gether/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../features/auth/fakes/fake_auth_repository.dart';
import '../../features/listing/fakes/fake_listing_repository.dart';
import '../../features/profile/fakes/fake_profile_repository.dart';
import '../cities/fake_cities.dart';

/// Monta el router real en `/onboarding`, que es la pantalla de perfil a la que
/// se llega tras confirmar el correo. Al ser ruta raíz no pasa por el shell, así
/// que el encuadre de escritorio tiene que ponerlo la propia ruta.
Widget _app() {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      profileRepositoryProvider.overrideWithValue(
        FakeProfileRepository(profile: fakeProfile(displayName: 'Ana')),
      ),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      listingRepositoryProvider.overrideWithValue(FakeListingRepository()),
      citiesRepositoryProvider.overrideWithValue(FakeCitiesRepository()),
    ],
    child: MaterialApp.router(
      routerConfig: buildAppRouter(initialLocation: '/onboarding'),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

double _profileWidth(WidgetTester tester) {
  return tester.getSize(find.byType(EditProfileScreen)).width;
}

void main() {
  group('encuadre de /onboarding', () {
    testWidgets(
      'en escritorio no se estira: mismo ancho que la pestaña Perfil',
      (tester) async {
        _setSize(tester, const Size(1400, 900));
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        expect(find.byType(EditProfileScreen), findsOneWidget);
        expect(_profileWidth(tester), kProfileContentMaxWidth);
      },
    );

    testWidgets('en la web desde el móvil ocupa todo el ancho, como antes', (
      tester,
    ) async {
      _setSize(tester, const Size(400, 800));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(_profileWidth(tester), 400);
    });
  });
}
