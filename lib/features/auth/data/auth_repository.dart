import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'auth_redirect.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
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

  /// Confirma el registro con el `token_hash` del enlace del correo.
  ///
  /// A diferencia de [exchangeCode], no necesita el `code_verifier` que PKCE
  /// guarda en el navegador donde se hizo el registro: el token se valida
  /// contra el servidor. Por eso el enlace funciona aunque se abra en otro
  /// dispositivo o navegador (p. ej. registrarse en el ordenador y confirmar
  /// desde el móvil).
  ///
  /// [type] es el valor que viaja en el enlace (`signup`, `recovery`…).
  Future<Session> verifyEmailToken({required String tokenHash, String? type});

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
    required String displayName,
    required DateTime birthdate,
  }) {
    // El trigger handle_new_user lee de los metadatos 'birthdate' (yyyy-MM-dd)
    // y 'display_name'. Si no le llegara nombre usaría la parte local del
    // email como respaldo, pero el formulario lo exige, así que el perfil nace
    // siempre con el nombre que eligió el usuario.
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailConfirmRedirectUrl(),
      data: {
        'display_name': displayName,
        'birthdate': birthdate.toIso8601String().substring(0, 10),
      },
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
  Future<Session> verifyEmailToken({
    required String tokenHash,
    String? type,
  }) async {
    final response = await _client.auth.verifyOTP(
      tokenHash: tokenHash,
      type: parseOtpType(type),
    );
    // verifyOTP lanza AuthException si la verificación no produce sesión, así
    // que llegados aquí nunca es null.
    return response.session!;
  }

  @override
  Session? get currentSession => _client.auth.currentSession;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(supabase);
});

/// Traduce el parámetro `type` del enlace del correo al enum de gotrue.
///
/// El único enlace que la app envía hoy es el de confirmación de registro
/// (`type=signup`), así que un valor ausente o desconocido se trata como
/// `signup`: si el servidor no lo acepta, responde con un error que ya se
/// traduce al español, en vez de romper el canje por adelantado.
OtpType parseOtpType(String? type) {
  switch (type) {
    case 'email':
      return OtpType.email;
    case 'magiclink':
      return OtpType.magiclink;
    case 'recovery':
      return OtpType.recovery;
    case 'invite':
      return OtpType.invite;
    case 'email_change':
      return OtpType.emailChange;
    case 'signup':
    default:
      return OtpType.signup;
  }
}
