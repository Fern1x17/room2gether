/// Fallo de autenticación ya traducido al español, con las banderas que la
/// interfaz necesita para ofrecer la salida adecuada.
///
/// Se guarda como error del `AsyncValue` del controlador. [toString] devuelve
/// el mensaje, así que los sitios que solo lo pintan (snackbars) siguen
/// funcionando sin cambios.
class AuthFailure {
  const AuthFailure(this.message, {this.emailNotConfirmed = false});

  final String message;

  /// El login falló porque la cuenta existe pero no ha confirmado el email.
  /// La pantalla lo usa para ofrecer reenviar el correo de confirmación.
  final bool emailNotConfirmed;

  @override
  String toString() => message;
}
