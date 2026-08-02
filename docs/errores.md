Documento para notificar errores

=== SIN ARREGLAR ===




=== ARREGLADOS ===

**Crear cuentas** (corregido 2026-08-02, pendiente de validación manual en
producción):

1- Al entrar en el enlace del correo de autenticación aparece una pantalla de
   error.
   Causa: la web usa hash URL strategy, así que la ruta va tras `#`, pero
   Supabase escribe sus parámetros en el query string, que en una URL va
   siempre ANTES del fragmento. La app aterrizaba en
   `room2gether.com/?code=XXX#/auth/callback` y go_router, que solo ve el
   fragmento, recibía la ruta sin ningún parámetro: sin código que canjear,
   pantalla de error.
   Solución: los parámetros se leen de la URL real del navegador (query y
   fragmento) en `auth_redirect.dart`, y el router arranca en la pantalla de
   confirmación llegue el enlace en la forma que llegue.

2- Al pasar mucho tiempo sin entrar en el enlace del correo, este expira y no se
   puede reenviar.
   Causa: el botón de reenviar solo existía en la pantalla intermedia, que se
   perdía al cerrar o recargar la pestaña. Quien volvía al día siguiente no
   tenía ninguna forma de pedir otro enlace.
   Solución: el login detecta el error `email_not_confirmed` y muestra un aviso
   con botón de reenvío (cooldown de 30 s). Además, un enlace caducado lleva
   ahora a `/login?confirm=pending`, que enseña ese aviso directamente.

3- Como al entrar en el enlace sale un error la cuenta no se queda autenticada
   por lo que no se puede crear una cuenta.
   Era consecuencia del fallo 1: al no canjearse nunca el token, no se creaba
   sesión. Resuelto con el mismo cambio.

4- La pantalla intermedia de reenviar correo me parece innecesaria, pondría el
   botón de reenviar en la misma pestaña de crear cuenta.
   Solución: eliminada `ConfirmEmailScreen` y su ruta `/confirm-email`. Ahora
   la propia pantalla de registro cambia el formulario por un aviso con el
   botón de reenviar (`ConfirmEmailPanel`), conservando el auto-login por
   polling. "Cambiar el email" devuelve al formulario con los datos escritos.

Cambios relacionados que no estaban en la lista:

- El enlace del correo ya no falla al abrirlo en otro dispositivo. La plantilla
  de Supabase pasó de `{{ .ConfirmationURL }}` (flujo PKCE, que exige el
  `code_verifier` guardado en el navegador que hizo el registro) a
  `token_hash`, que se valida contra el servidor. Se admiten las dos formas.
- La confirmación tiene pantalla propia (`EmailConfirmationScreen`), accesible
  solo desde el enlace y solo en web: quien abra la URL a mano acaba en el
  inicio. Al confirmar no navega sola; muestra "¡Cuenta confirmada!" con un
  botón "Entrar".

**Eliminar mensajes**: Los mensajes se eliminan de la base de datos pero siguen
apareciendo en el chat.
