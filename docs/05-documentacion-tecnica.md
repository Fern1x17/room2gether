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
  caracteres) y fecha de nacimiento (mayor de 18 años, menor de 120), funciones
  puras. `ageInYears()` calcula la edad exacta teniendo en cuenta si el
  cumpleaños de este año ya pasó.
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
`security definer` y lee la fecha de nacimiento de los metadatos pasados en
`signUp(data: {...})`.

**Fecha de nacimiento en vez de edad (migración `20260702000009`):** el registro
pide la fecha de nacimiento con un selector de fecha (no la edad como número).
En la BD, `profiles.age` (int) se sustituyó por `profiles.birthdate` (date, NOT
NULL) con el check `profiles_adult_check` (mayoría de edad, RF-02). Las filas
existentes se rellenaron aproximando la fecha desde la edad (quedan con el
aniversario en la fecha de la migración; el día/mes real no era recuperable).
La misma migración añade `profiles.role` (text: 'user' / 'moderator', default
'user') — el campo "tipo" del modelo de datos, renombrado a `role` en inglés
por la convención del proyecto. El rol no es editable desde el cliente; los
moderadores se promocionan desde el servidor con `service_role`. De momento el
rol solo existe como dato: no hay todavía ninguna política RLS ni pantalla que
dé privilegios especiales a los moderadores (pendiente de especificar).

**Sesión persistente (RF-13):** `supabase_flutter` guarda la sesión en el
dispositivo y la restaura durante `Supabase.initialize()` en el arranque. El
router lo aprovecha: si al crear el `GoRouter` existe `currentSession`, la app
arranca directamente en `/feed` en vez de en la pantalla de bienvenida. La
sesión solo se destruye al pulsar "Cerrar sesión" (CU-05); matar la app no la
cierra.

**Cómo probarlo a mano:** `/` → "Crear cuenta" → rellenar formulario → si el
proyecto no exige confirmación de email, navega directo a `/onboarding`; si la
exige, muestra aviso y vuelve a `/login`. Para RF-13: iniciar sesión, matar la
app por completo, reabrirla → debe aparecer el feed directamente sin pedir
credenciales; tras "Cerrar sesión" y reabrir, debe aparecer la bienvenida.

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
`display_name`, `bio` y `avatar_url`. **No** incluye `birthdate` (no forma parte
de la descripción de esta feature en CLAUDE.md — se fija en el registro) ni
`is_verified`/`role` (flags de sistema, no editables por el usuario).

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
sube en cuanto se selecciona (no espera a "Guardar cambios") y en ese mismo
momento se escribe la URL pública en `profiles.avatar_url` — así la foto
persiste entre sesiones aunque el usuario salga de la app sin pulsar guardar.

**Decisión técnica:** los datos del formulario se inicializan una sola vez desde
el `Profile` cargado (flag `_initialized` en `EditProfileScreen`), para no pisar
lo que el usuario esté escribiendo si el provider se reconstruye.

**Cómo probarlo a mano:**
1. Desde `/feed`, pulsar el icono de perfil → llega a `/onboarding` (pantalla
   de perfil). Justo después de registrarse también se llega aquí directo.
2. Cambiar nombre, ciudad, presupuesto, preferencias y foto → "Guardar cambios"
   → confirma con un SnackBar.
3. Volver a entrar más tarde → los datos guardados aparecen precargados.
4. Pulsar el icono de cerrar sesión → confirmar en el diálogo → vuelve a
   `/login` y la sesión queda cerrada (comprobable reiniciando la app: pide
   login de nuevo).

---

## Feed (CU-09 Explorar y filtrar el feed)

**Carpeta:** `lib/features/feed/`

- `domain/models/listing.dart` — modelo `Listing` (mapea con la tabla `listings`).
- `domain/models/listing_filter.dart` — criterios de búsqueda: `city`,
  `neighborhood`, `maxPrice`, `type`. Son exactamente los tres que fija RF-06
  ("zona, precio, tipo"); ver nota sobre "estado" más abajo.
- `data/feed_repository.dart` — `FeedRepository`: `fetchListings(filter)` (solo
  `status = 'active'`, con los filtros aplicados como condiciones adicionales)
  y `fetchListingById(id)` para el detalle.
- `data/recent_searches_repository.dart` — búsquedas recientes guardadas SOLO
  en el dispositivo con `shared_preferences` (decisión ya acordada), como lista
  de hasta 10 filtros, sin duplicados, más reciente primero.
- `presentation/controllers/feed_controller.dart` — `AsyncNotifier<List<Listing>>`;
  `build()` carga publicaciones de la ciudad del propio perfil (comentario de
  CU-09: "en la pantalla principal aparecerán publicaciones de la ciudad que
  haya seleccionado"); `search(filter)` aplica un filtro nuevo y lo guarda en
  recientes.
- `presentation/controllers/listing_detail_controller.dart` — `FutureProvider.family`
  para cargar una publicación por id.
- `presentation/screens/feed_screen.dart` — pantalla principal: lista de
  publicaciones, icono de buscar (abre `FiltersSheet`) e icono para ir al
  perfil.
- `presentation/screens/listing_detail_screen.dart` — vista mínima de detalle
  (tipo, título, ubicación, precio, descripción). Se añade ahora, aunque CU-09
  no la pide explícitamente, porque CU-10 (Contactar por chat) exige poder
  "seleccionar una publicación de la feed" para llegar a ella — es la plomería
  mínima que ese caso de uso necesitará; **no** incluye ningún botón de
  contactar/enviar mensaje todavía, eso es trabajo de CU-10.
- `presentation/widgets/{listing_card,filters_sheet}.dart`.

**Nota sobre "estado" en CU-09:** el texto del caso de uso dice "ciudad, barrio,
precio, estado..." pero RF-06 (la fuente más específica) dice "zona, precio,
tipo". Se ha interpretado "estado" como el tipo de publicación (busco/ofrezco),
no como `listings.status` (activa/cerrada) — filtrar por publicaciones cerradas
no tendría sentido en un feed público, y RLS ya solo expone las activas a
usuarios no propietarios.

**Decisión pendiente resuelta — acceso sin sesión:** la precondición de CU-09 es
"N/A" (a diferencia del resto de casos de uso), lo que sugiere que se podría
explorar sin cuenta. Sin embargo hoy las políticas RLS de `listings` solo
permiten `SELECT` al rol `authenticated`. Se decidió **no** tocar RLS por ahora
y exigir sesión igual que el resto de la app; si más adelante se quiere permitir
exploración sin cuenta, hace falta una política RLS nueva para el rol `anon`
(cambio de base de datos que requiere decisión aparte).

**Navegación:** tras iniciar sesión (CU-02) ahora se llega a `/feed` en vez de
a `/onboarding` — el feed es "la pantalla principal" según los propios
comentarios de CU-09. El registro (CU-01) sigue llevando a `/onboarding`
(completar perfil) tal como pide su postcondición. Cada pantalla tiene un
icono para ir a la otra.

**Cómo probarlo a mano:**
1. Insertar un par de filas de prueba en `listings` (no hay UI para crear
   publicaciones todavía — eso es CU-06) y comprobar que aparecen en `/feed`.
2. Pulsar el icono de buscar, aplicar un filtro de ciudad/precio/tipo → la
   lista se actualiza y la búsqueda queda guardada como "reciente".
3. Reabrir el panel de filtros → la búsqueda anterior aparece como chip en
   "Búsquedas recientes"; tocarla la vuelve a aplicar.
4. Tocar una publicación → se abre el detalle con sus datos.
5. Con el feed vacío (sin filas de prueba) se muestra el mensaje "No hay
   publicaciones que coincidan con tu búsqueda." en vez de una lista vacía sin
   explicación.
