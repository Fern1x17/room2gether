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
