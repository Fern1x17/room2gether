import 'package:flutter/foundation.dart' show kIsWeb;

/// URL a la que Supabase debe redirigir tras confirmar el email.
///
/// La web usa hash URL strategy (no hay `usePathUrlStrategy()`), así que la
/// ruta del callback va tras `#`. Se construye desde [Uri.base] para que
/// funcione igual en room2gether.com y en `localhost` durante el desarrollo,
/// sin hardcodear el dominio.
///
/// En plataformas no-web (móvil) la confirmación por enlace todavía no está
/// cableada (haría falta un deep link con esquema propio), así que devolvemos
/// `null` y Supabase usa su Site URL por defecto.
///
/// Nota: esta URL debe estar dada de alta en Supabase → Auth → URL
/// Configuration → Redirect URLs para que la confirmación redirija aquí.
String? emailConfirmRedirectUrl() {
  if (!kIsWeb) return null;
  return '${Uri.base.origin}/#/auth/callback';
}

/// Parámetros que llegan en la URL al pulsar el enlace de confirmación.
///
/// Hay dos formas posibles según la plantilla de correo configurada en
/// Supabase:
/// - `token_hash` + `type`: la plantilla apunta directamente a la app. Se
///   verifica contra el servidor, así que **funciona en cualquier dispositivo**.
///   Es la que usa el proyecto.
/// - `code`: flujo PKCE, cuando la plantilla usa `{{ .ConfirmationURL }}`. Solo
///   se puede canjear en el navegador que hizo el registro.
///
/// Y si el enlace caducó o ya se usó, en vez de token llega la descripción del
/// error.
class AuthCallbackParams {
  const AuthCallbackParams({
    this.code,
    this.tokenHash,
    this.type,
    this.errorDescription,
  });

  final String? code;
  final String? tokenHash;
  final String? type;
  final String? errorDescription;

  bool get isEmpty =>
      code == null && tokenHash == null && errorDescription == null;
  bool get isNotEmpty => !isEmpty;
}

/// Lee los parámetros del callback de la URL con la que se abrió la app.
///
/// Hace falta porque Supabase **no** los deja donde la hash URL strategy los
/// puede ver. GoTrue construye la vuelta parseando el `redirect_to` y
/// escribiendo los parámetros en el query string, que en una URL va siempre
/// ANTES del fragmento. Con `redirect_to = https://dominio/#/auth/callback` el
/// usuario aterriza en `https://dominio/?code=XXX#/auth/callback`, y go_router
/// —que solo ve el fragmento— recibe la ruta `/auth/callback` sin ningún
/// parámetro. Si además el `redirect_to` no está en la allow-list, Supabase cae
/// al Site URL y la vuelta es `https://dominio/?code=XXX`, sin fragmento
/// siquiera; y si el enlace caducó, el error puede llegar como
/// `https://dominio/#error=access_denied&error_description=...`, que no
/// corresponde a ninguna ruta.
///
/// Por eso se mira la URL real del navegador ([Uri.base]) y no solo lo que el
/// router haya conseguido interpretar.
AuthCallbackParams authCallbackParamsFromLaunchUrl() {
  return parseAuthCallbackParams(Uri.base);
}

/// Extrae los parámetros del callback de [url], mirando tanto el query string
/// como el fragmento. Separada de [authCallbackParamsFromLaunchUrl] para poder
/// probarla con URLs concretas.
AuthCallbackParams parseAuthCallbackParams(Uri url) {
  final params = <String, String>{
    ...url.queryParameters,
    ..._fragmentParams(url.fragment),
  };

  return AuthCallbackParams(
    code: _nonEmpty(params['code']),
    tokenHash: _nonEmpty(params['token_hash']),
    type: _nonEmpty(params['type']),
    errorDescription:
        _nonEmpty(params['error_description']) ?? _nonEmpty(params['error']),
  );
}

/// Parámetros codificados dentro del fragmento, en sus dos formas posibles:
/// `#/auth/callback?code=XXX` (tras la ruta) y `#error=...&error_code=...`
/// (el fragmento entero es la lista de parámetros).
Map<String, String> _fragmentParams(String fragment) {
  if (fragment.isEmpty) return const {};

  final queryStart = fragment.indexOf('?');
  final query = queryStart >= 0 ? fragment.substring(queryStart + 1) : fragment;
  if (!query.contains('=')) return const {};

  try {
    return Uri.splitQueryString(query);
  } on FormatException {
    return const {};
  }
}

String? _nonEmpty(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}
