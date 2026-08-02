import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/layout/breakpoints.dart';
import 'package:room2gether/core/places/places_service.dart';
import 'package:room2gether/core/router/app_router.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/auth/data/auth_repository.dart';
import 'package:room2gether/features/listing/data/listing_repository.dart';
import 'package:room2gether/features/listing/presentation/screens/create_listing_screen.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';
import 'package:room2gether/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../features/auth/fakes/fake_auth_repository.dart';
import '../../features/listing/fakes/fake_listing_repository.dart';
import '../../features/profile/fakes/fake_profile_repository.dart';
import '../cities/fake_cities.dart';
import '../places/fake_places.dart';

/// Las rutas raíz (`/onboarding`, `/listings/new`) son pantallas completas que
/// no pasan por el shell, así que el encuadre de escritorio tiene que ponerlo
/// la propia ruta o el formulario se estira de borde a borde.
Widget _app(String initialLocation) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      profileRepositoryProvider.overrideWithValue(
        FakeProfileRepository(profile: fakeProfile(displayName: 'Ana')),
      ),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      listingRepositoryProvider.overrideWithValue(FakeListingRepository()),
      citiesRepositoryProvider.overrideWithValue(FakeCitiesRepository()),
      placesServiceProvider.overrideWithValue(FakePlacesService()),
    ],
    child: MaterialApp.router(
      routerConfig: buildAppRouter(initialLocation: initialLocation),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('encuadre de /onboarding', () {
    testWidgets(
      'en escritorio no se estira: mismo ancho que la pestaña Perfil',
      (tester) async {
        _setSize(tester, const Size(1400, 900));
        await tester.pumpWidget(_app('/onboarding'));
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(EditProfileScreen)).width,
          kContentPageMaxWidth,
        );
      },
    );

    testWidgets('en la web desde el móvil ocupa todo el ancho, como antes', (
      tester,
    ) async {
      _setSize(tester, const Size(400, 800));
      await tester.pumpWidget(_app('/onboarding'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(EditProfileScreen)).width, 400);
    });
  });

  group('encuadre de /listings/new', () {
    testWidgets('en escritorio no se estira', (tester) async {
      _setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(_app('/listings/new'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(CreateListingScreen)).width,
        kContentPageMaxWidth,
      );
    });

    testWidgets('en la web desde el móvil ocupa todo el ancho, como antes', (
      tester,
    ) async {
      _setSize(tester, const Size(400, 800));
      await tester.pumpWidget(_app('/listings/new'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(CreateListingScreen)).width, 400);
    });
  });
}
