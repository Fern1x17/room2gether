import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../utils/auth_error_translator.dart';

class SignOutController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Devuelve `true` si se cerró la sesión correctamente.
  Future<bool> signOut() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(translateAuthError(error), stackTrace);
      return false;
    }
  }
}

final signOutControllerProvider =
    AsyncNotifierProvider<SignOutController, void>(SignOutController.new);
