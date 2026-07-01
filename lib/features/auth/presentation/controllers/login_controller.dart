import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../utils/auth_error_translator.dart';

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Devuelve la [AuthResponse] si el login fue correcto, o `null` si falló
  /// (en ese caso el estado del provider queda en [AsyncError] con el mensaje
  /// ya traducido al español).
  Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signIn(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      return response;
    } catch (error, stackTrace) {
      state = AsyncError(translateAuthError(error), stackTrace);
      return null;
    }
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
