import 'package:supabase_flutter/supabase_flutter.dart';

String translateAuthError(Object error) {
  if (error is AuthException) {
    // gotrue >= 2.x expone un `code` estable; lo preferimos a comparar el
    // mensaje (que cambia entre versiones y locales). Mantenemos el string
    // como respaldo por si `code` viene null en algún caso.
    final code = error.code;
    final message = error.message.toLowerCase();

    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión.';
    }
    if (code == 'over_email_send_rate_limit' ||
        message.contains('rate limit')) {
      return 'Has pedido demasiados correos. Espera un momento e inténtalo de nuevo.';
    }
    if (code == 'weak_password' || message.contains('password')) {
      return 'La contraseña no cumple los requisitos mínimos.';
    }
  }
  return 'Ha ocurrido un error. Inténtalo de nuevo.';
}

/// `true` si el error corresponde a "email todavía sin confirmar", el caso que
/// el polling de la pantalla de espera debe tratar como "sigue esperando" en
/// lugar de como un fallo real.
bool isEmailNotConfirmedError(Object error) {
  if (error is! AuthException) return false;
  return error.code == 'email_not_confirmed' ||
      error.message.toLowerCase().contains('email not confirmed');
}
