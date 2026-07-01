# Documentación técnica — Roomie

> Documentación del código ya construido: qué se hizo, decisiones técnicas y
> cómo probarlo a mano. Distinta de los documentos de especificación (`01`, `02`,
> `03`): esos describen QUÉ debe hacer la app; este describe CÓMO se ha construido.
> Se amplía por feature, a medida que se completan casos de uso.

---

## Auth (CU-01 Registrarse, CU-02 Iniciar sesión)

**Carpeta:** `lib/features/auth/`

- `data/auth_repository.dart` — `AuthRepository` (abstracta) + `SupabaseAuthRepository`.
  Encapsula `signUp`, `signIn` y `signOut` de Supabase Auth.
- `domain/validators/auth_validators.dart` — validación de email, contraseña (mín. 8
  caracteres) y edad (18–120), funciones puras.
- `presentation/controllers/{register,login}_controller.dart` — `AsyncNotifier<void>`,
  gestionan carga/error de cada flujo por separado (para que un error en una
  pantalla no contamine el estado de la otra).
- `presentation/screens/{welcome,login,register}_screen.dart`.
- `presentation/utils/auth_error_translator.dart` — traduce `AuthException` a
  mensajes en español.

**Decisión técnica clave:** la fila de `profiles` se crea automáticamente con un
trigger de Postgres (`supabase/migrations/20260701000007_profiles_auto_create_on_signup.sql`),
no con un insert desde el cliente. Motivo: si el proyecto tuviera confirmación de
email activada, `signUp()` no devolvería sesión activa y un insert desde Flutter
fallaría por RLS (`auth.uid()` sería null en ese momento). El trigger usa
`security definer` y lee la edad de los metadatos pasados en `signUp(data: {...})`.

**Cómo probarlo a mano:** `/` → "Crear cuenta" → rellenar formulario → si el
proyecto no exige confirmación de email, navega directo a `/onboarding`; si la
exige, muestra aviso y vuelve a `/login`.

---

## Perfil (CU-04 Modificar perfil, CU-05 Cerrar sesión)

**Carpeta:** `lib/features/profile/`

- `domain/models/profile.dart` — modelo `Profile` (mapea 1:1 con la tabla
  `profiles`, excepto `created_at`/`updated_at` que no hacen falta en el cliente).
- `domain/validators/profile_validators.dart` — nombre obligatorio, rango de
  presupuesto (`budget_min <= budget_max`, mismo criterio que el `check` de la
  tabla), nivel de limpieza 1–5.
- `data/profile_repository.dart` — `ProfileRepository` (abstracta) +
  `SupabaseProfileRepository`: `fetchMyProfile`, `updateProfile`, `uploadAvatar`.
- `presentation/controllers/profile_controller.dart` — `AsyncNotifier<Profile>`;
  `build()` carga el perfil del usuario autenticado, `save()` actualiza.
- `presentation/screens/edit_profile_screen.dart` — formulario completo
  (nombre, bio, ciudad, presupuesto min/max, fumador, mascotas, nivel de
  limpieza, horario, foto) + botón de cerrar sesión con confirmación.

**Campos incluidos:** los que CLAUDE.md especifica para "Perfil" en el plan de
Fase 1 (horarios, limpieza, fumador, mascotas, presupuesto, zona) más
`display_name`, `bio` y `avatar_url`. **No** incluye `age` (no forma parte de la
descripción de esta feature en CLAUDE.md — se fija en el registro) ni
`is_verified` (flag de sistema, no editable por el usuario).

**Reutilización de pantalla:** esta misma pantalla (`EditProfileScreen`) es el
destino de la ruta `/onboarding`, que CU-01 prometía como "onboarding de
perfil". Sustituye al antiguo `OnboardingPlaceholderScreen` (eliminado) en vez
de crear una pantalla duplicada.

**Cierre de sesión (CU-05):** botón de logout en el `AppBar` → diálogo de
confirmación → `SignOutController` (`lib/features/auth/presentation/controllers/sign_out_controller.dart`,
nuevo, añade `signOut()` a `AuthRepository`) → si va bien, navega a `/login`.

**Foto de perfil — Supabase Storage:** bucket `avatars` (público en lectura),
creado en `supabase/migrations/20260701000008_avatars_storage_bucket.sql`. Cada
usuario solo puede subir/actualizar/borrar objetos dentro de su propia carpeta
`{user_id}/...` (política RLS basada en `storage.foldername(name)`). El cliente
usa `image_picker` (nueva dependencia) para elegir la foto de la galería; se
sube en cuanto se selecciona (no espera a "Guardar cambios") y la URL pública
resultante se guarda en `avatar_url` al guardar el formulario.

**Decisión técnica:** los datos del formulario se inicializan una sola vez desde
el `Profile` cargado (flag `_initialized` en `EditProfileScreen`), para no pisar
lo que el usuario esté escribiendo si el provider se reconstruye.

**Cómo probarlo a mano:**
1. Iniciar sesión → llega a `/onboarding` (pantalla de perfil).
2. Cambiar nombre, ciudad, presupuesto, preferencias y foto → "Guardar cambios"
   → confirma con un SnackBar.
3. Volver a entrar más tarde → los datos guardados aparecen precargados.
4. Pulsar el icono de cerrar sesión → confirmar en el diálogo → vuelve a
   `/login` y la sesión queda cerrada (comprobable reiniciando la app: pide
   login de nuevo).
