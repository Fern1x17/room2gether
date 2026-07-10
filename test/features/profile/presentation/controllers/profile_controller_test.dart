import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/supabase/current_user_provider.dart';
import 'package:room2gether/features/profile/data/profile_repository.dart';
import 'package:room2gether/features/profile/presentation/controllers/profile_controller.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  group('ProfileController', () {
    test('build() carga el perfil desde el repositorio', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(profile: fakeProfile(displayName: 'Ana')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(profileControllerProvider.future);

      expect(profile.displayName, 'Ana');
    });

    test('save() actualiza el estado y devuelve true si va bien', () async {
      final fakeRepo = FakeProfileRepository();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          profileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileControllerProvider.future);
      final updated = fakeProfile(displayName: 'Nuevo nombre');

      final ok = await container
          .read(profileControllerProvider.notifier)
          .save(updated);

      expect(ok, isTrue);
      expect(fakeRepo.lastSavedProfile?.displayName, 'Nuevo nombre');
      expect(
        container.read(profileControllerProvider).value?.displayName,
        'Nuevo nombre',
      );
    });

    test(
      'save() devuelve false y deja error si el repositorio falla',
      () async {
        final fakeRepo = FakeProfileRepository(updateError: Exception('fallo'));
        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileControllerProvider.future);
        final ok = await container
            .read(profileControllerProvider.notifier)
            .save(fakeProfile(displayName: 'X'));

        expect(ok, isFalse);
        expect(container.read(profileControllerProvider).hasError, isTrue);
      },
    );

    test('uploadAvatar() devuelve la URL pública', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(
              uploadAvatarUrl: 'https://example.com/foto.jpg',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileControllerProvider.future);
      final url = await container
          .read(profileControllerProvider.notifier)
          .uploadAvatar(bytes: Uint8List(0), fileExtension: 'jpg');

      expect(url, 'https://example.com/foto.jpg');
    });

    test(
      'uploadAvatar() persiste la URL en el perfil sin esperar a guardar',
      () async {
        final fakeRepo = FakeProfileRepository(
          uploadAvatarUrl: 'https://example.com/foto.jpg',
        );
        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileControllerProvider.future);
        await container
            .read(profileControllerProvider.notifier)
            .uploadAvatar(bytes: Uint8List(0), fileExtension: 'jpg');

        // La URL queda escrita en la BD (updateProfile) y en el estado, de modo
        // que sobrevive a cerrar sesión o salir de la app sin pulsar guardar.
        expect(
          fakeRepo.lastSavedProfile?.avatarUrl,
          'https://example.com/foto.jpg',
        );
        expect(
          container.read(profileControllerProvider).value?.avatarUrl,
          'https://example.com/foto.jpg',
        );
      },
    );

    test('uploadAvatar() devuelve null si falla la persistencia', () async {
      final fakeRepo = FakeProfileRepository(
        uploadAvatarUrl: 'https://example.com/foto.jpg',
        updateError: Exception('fallo'),
      );
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          profileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileControllerProvider.future);
      final url = await container
          .read(profileControllerProvider.notifier)
          .uploadAvatar(bytes: Uint8List(0), fileExtension: 'jpg');

      expect(url, isNull);
    });
  });
}
