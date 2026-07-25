import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'auth_redirect.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required DateTime birthdate,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Reenvía el correo de confirmación de registro (CU-01, RF-13).
  Future<void> resendSignupConfirmation({required String email});

  /// Canjea el código PKCE del enlace de confirmación por una sesión. La
  /// sesión resultante pertenece a la cuenta del token, sobrescribiendo
  /// cualquier sesión previa en este navegador.
  Future<Session> exchangeCode(String code);

  /// Sesión actualmente activa en el dispositivo, o `null` si no hay ninguna.
  Session? get currentSession;
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required DateTime birthdate,
  }) {
    // El trigger handle_new_user lee 'birthdate' (yyyy-MM-dd) de los metadatos.
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailConfirmRedirectUrl(),
      data: {'birthdate': birthdate.toIso8601String().substring(0, 10)},
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: emailConfirmRedirectUrl(),
    );
  }

  @override
  Future<Session> exchangeCode(String code) async {
    final response = await _client.auth.exchangeCodeForSession(code);
    return response.session;
  }

  @override
  Session? get currentSession => _client.auth.currentSession;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(supabase);
});
