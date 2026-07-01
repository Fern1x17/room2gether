import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../utils/auth_error_translator.dart';

class RegisterController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Devuelve la [AuthResponse] si el registro fue correcto, o `null` si falló
  /// (en ese caso el estado del provider queda en [AsyncError] con el mensaje
  /// ya traducido al español).
  Future<AuthResponse?> register({
    required String email,
    required String password,
    required int age,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUp(
        email: email,
        password: password,
        age: age,
      );
      state = const AsyncData(null);
      return response;
    } catch (error, stackTrace) {
      state = AsyncError(translateAuthError(error), stackTrace);
      return null;
    }
  }
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, void>(RegisterController.new);
