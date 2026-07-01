import 'package:supabase_flutter/supabase_flutter.dart';

String translateAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión.';
    }
    if (message.contains('password')) {
      return 'La contraseña no cumple los requisitos mínimos.';
    }
  }
  return 'Ha ocurrido un error. Inténtalo de nuevo.';
}
