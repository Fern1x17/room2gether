# Documentación técnica — Room2gether

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

---

## Publicación (CU-06 Crear publicación)

**Carpeta:** `lib/features/listing/`

- `domain/listing_policy.dart` — la precondición "no tiene ninguna publicación
  activa" vive aquí como regla centralizada (`maxActiveListingsPerUser = 1` +
  `canCreateListing()`). Decisión acordada: se comprueba **solo en la app**,
  sin constraint en BD, y en un único sitio para poder cambiarla fácilmente.
- `domain/models/listing_draft.dart` — datos del formulario según el tipo.
- `domain/validators/listing_validators.dart` — título, ciudad, barrio
  (obligatorio solo en 'offering'), precio ('offering'), rango de presupuesto
  ('seeking', min ≤ max) y fotos (≥1 solo en 'offering'), tal como exige el
  flujo de CU-06.
- `data/listing_repository.dart` — cuenta publicaciones activas propias, sube
  fotos al bucket `listing-photos` (carpeta `{user_id}/`) e inserta la fila.
- `presentation/controllers/create_listing_controller.dart` — comprueba la
  precondición, sube fotos y crea; estados de carga/error.
- `presentation/screens/create_listing_screen.dart` — selector "Tengo piso y
  busco compañero" / "Busco piso y compañero"; según el tipo pide fotos+precio
  o rango de presupuesto; ciudad, barrio (vacío = "cualquiera" al buscar),
  título y descripción opcional. Entrada: botón flotante "Crear publicación"
  en el feed (ruta `/listings/new`, declarada antes de `/listings/:id`).

**Cambios de esquema (aprobados):** migraciones `20260707000010` (bucket
`listing-photos`, mismo patrón RLS que `avatars`) y `20260707000011`
(`budget_min`/`budget_max` en `listings`, `price` pasa a nullable y un check
por tipo: 'offering' exige price, 'seeking' exige rango válido; las filas
'seeking' existentes movieron su price al rango).

**Decisiones de alcance:**
- El campo "Título" se añadió al formulario por decisión del usuario (el flujo
  de CU-06 no lo mencionaba pero la tabla lo exige).
- El filtro de precio del feed aplica ahora a `price` (offering) **o**
  `budget_max` (seeking), para que las publicaciones de quien busca piso no
  desaparezcan al filtrar por precio.
- El detalle de publicación muestra la galería de fotos (postcondición:
  "cualquiera puede verla").

**Cómo probarlo a mano:**
1. Feed → "Crear publicación" → elegir "Tengo piso...": exige ≥1 foto, precio
   y barrio. Elegir "Busco piso...": exige rango de presupuesto y el barrio
   puede quedar vacío.
2. Publicar → vuelve al feed y la publicación aparece (con "X–Y €/mes" si es
   'busco').
3. Intentar crear una segunda publicación → bloqueado con aviso "Ya tienes una
   publicación activa."
4. Abrir el detalle → se ven las fotos subidas.

---

## Publicación (CU-07 Eliminar publicación)

**Ficheros nuevos/tocados:**

- `lib/features/listing/presentation/controllers/my_listings_controller.dart` —
  `myListingsProvider` (publicaciones propias) y `DeleteListingController`.
- `lib/features/listing/presentation/widgets/my_listings_section.dart` —
  sección "Tus publicaciones" mostrada dentro de la pantalla de perfil (el
  flujo de CU-07/CU-08 dice "entra en el perfil y selecciona una publicación");
  cada elemento navega al detalle.
- `lib/features/listing/data/listing_repository.dart` — `fetchMyListings()` y
  `deleteListing()` (borrado real de la fila, según la postcondición
  "eliminada de la base de datos"; RLS solo permite borrar las propias).
- `lib/features/feed/presentation/screens/listing_detail_screen.dart` — botón
  "Eliminar publicación" con diálogo de confirmación, visible solo si la
  publicación es del usuario autenticado (`currentUserIdProvider`, un provider
  para que los widgets no llamen a Supabase directamente).

**Decisiones:**
- El borrado es un DELETE real, no un cambio a status 'closed' — es lo que
  dice la postcondición. Las fotos del bucket no se borran (no lo pide el CU;
  quedan huérfanas en Storage — anotado por si se quiere limpiar más adelante).
- Tras eliminar se invalidan el feed y "Tus publicaciones", cumpliendo
  "eliminada... del perfil".

**Cómo probarlo a mano:**
1. Perfil → sección "Tus publicaciones" → tocar una → detalle con botón rojo
   "Eliminar publicación" (no aparece en publicaciones ajenas del feed).
2. Eliminar → confirmar → vuelve atrás; ya no está ni en el feed ni en el
   perfil, y se puede volver a crear una publicación nueva (la regla de "una
   activa" queda liberada).

---

## Publicación (CU-08 Modificar publicación)

**Ficheros nuevos/tocados:**

- `lib/features/listing/presentation/screens/create_listing_screen.dart` — el
  mismo formulario de CU-06 acepta ahora un `initial` (la publicación a
  editar): precarga todos los campos, muestra las fotos ya subidas (se pueden
  quitar y añadir nuevas) y el botón pasa a "Guardar cambios". Se puede
  cambiar el tipo (busco ↔ ofrezco); el formulario y el check de coherencia de
  la tabla se encargan de que los campos resultantes sean válidos.
- `lib/features/listing/presentation/screens/edit_listing_screen.dart` —
  wrapper de la ruta `/listings/:id/edit`: carga la publicación y abre el
  formulario en modo edición.
- `lib/features/listing/presentation/controllers/update_listing_controller.dart`
  — sube las fotos nuevas, conserva las que no se quitaron y actualiza la fila
  (el método se llama `save` porque `AsyncNotifier` ya define `update`).
- `lib/features/listing/data/listing_repository.dart` — `updateListing()`
  escribe todos los parámetros; RLS solo permite editar las propias.
- Detalle de publicación: botón "Modificar publicación" (solo propietario),
  encima del de eliminar.

**Cómo probarlo a mano:**
1. Perfil → "Tus publicaciones" → tocar una → "Modificar publicación".
2. El formulario aparece precargado (incluidas las fotos ya subidas).
3. Cambiar precio/título/quitar una foto → "Guardar cambios" → vuelve al
   detalle con los datos nuevos; el feed y el perfil también se actualizan.

---

## Chat (CU-10 Contactar por chat)

**Carpeta:** `lib/features/chat/`

- `domain/models/{conversation,message}.dart` — la conversación resuelve "el
  otro participante" (nombre/avatar) a partir de los dos perfiles embebidos.
- `data/chat_repository.dart` — `openConversation` reutiliza la conversación
  existente entre los 2 usuarios o la crea (postcondición CU-10);
  `fetchMyConversations` (join con `profiles` por las dos FKs),
  `sendMessage`, y `watchMessages` como stream de Supabase Realtime.
- `presentation/controllers/chat_controllers.dart` — providers de
  conversaciones/mensajes en vivo + controllers de abrir conversación y
  enviar (con carga/error; no se envían mensajes vacíos).
- `presentation/screens/chat_screen.dart` — burbujas alineadas por emisor,
  entrada de texto y envío; los mensajes del otro llegan en vivo.
- `presentation/screens/conversations_screen.dart` — pantalla "Chats"
  (aprobada como plomería necesaria para "entrar en un chat existente" de
  CU-11), accesible desde un icono en el feed.
- Entrada del flujo: botón "Enviar mensaje" en el detalle de una publicación
  ajena (paso 2 de CU-10). Rutas `/chats` y `/chats/:id`.

**Decisiones técnicas:**
- Migración `20260707000012` (aprobada): añade `messages` a la publicación
  `supabase_realtime`. RLS sigue aplicando: solo llegan mensajes de
  conversaciones en las que participas.
- **Cifrado ("se guarda cifrado"):** se usa el cifrado de plataforma de
  Supabase — TLS en tránsito y cifrado en reposo en Postgres — sin cifrado
  adicional a nivel de aplicación (decisión acordada para el MVP).
- `currentUserIdProvider` se movió a `lib/core/supabase/` porque ahora lo
  comparten feed y chat.
- Una conversación por pareja de usuarios: contactar de nuevo (aunque sea por
  otra publicación) reabre el mismo chat; `listing_id` guarda la publicación
  que lo originó.

**Cómo probarlo a mano** (hacen falta 2 cuentas):
1. Con la cuenta B, crear una publicación. Con la cuenta A, abrirla desde el
   feed → "Enviar mensaje" → escribir → aparece la burbuja.
2. Con la cuenta B, icono de chats en el feed → aparece el chat con A → abrir
   y responder. Con ambas apps abiertas, los mensajes llegan sin refrescar.
3. Volver a "Enviar mensaje" desde otra publicación del mismo usuario → se
   reabre el mismo chat (no se duplica).

### Edición y borrado de mensajes (Extensión CU-10)

**Ficheros nuevos/tocados:**

- `supabase/migrations/20260714000018_messages_delete_policy.sql` — **(aplicada
  al remoto el 2026-07-14 con `supabase db push --linked`)** crea la política
  RLS `messages_delete_sender` que permite el borrado de mensajes. Idempotente
  (`drop policy if exists` + `create policy`).
- `supabase/migrations/20260701000004_create_messages.sql` — se añadió la misma
  política al fichero original para que un `db reset` desde cero la incluya.
  Ojo: esa migración ya estaba aplicada en el remoto ANTES del cambio, por lo
  que editarla no tuvo efecto allí — de ahí la migración `...018` (lección:
  las migraciones aplicadas son inmutables; los cambios van en una nueva).
  La política de edición (`messages_update_participants`) ya existía para el
  `read_at` y no necesitó cambios.
- `lib/features/chat/data/chat_repository.dart` — Se añadieron los métodos `updateMessage(messageId, newContent)` y `deleteMessage(messageId)` (este último implementado como borrado lógico modificando el texto).
- `lib/features/chat/presentation/controllers/chat_controllers.dart` — Se creó `MessageActionsController` (`AsyncNotifier`) para gestionar los estados de carga y error de las acciones de modificar y borrar, evitando bloquear la UI.
- `lib/features/chat/presentation/screens/chat_screen.dart` — Se añadió un `GestureDetector` con `onLongPress` en las burbujas de texto. Despliega un menú inferior (`showModalBottomSheet`) y diálogos de confirmación/edición (`AlertDialog`). Se añadió la detección visual de mensajes eliminados.
- `test/features/chat/presentation/controllers/chat_controllers_test.dart` —
  tests de `MessageActionsController`: borrado y edición (caso feliz, contenido
  recortado, rechazo de vacíos y estados de error). El fake
  (`test/features/chat/fakes/fake_chat_repository.dart`) rastrea
  `deletedMessageIds` / `updatedMessages` y permite inyectar errores.

**Decisiones técnicas:**
- **Borrado Lógico (Soft Delete) vs Físico:** Para conseguir el efecto visual de "🚫 Este mensaje ha sido eliminado" y asegurar que la eliminación se propague en tiempo real a ambos clientes (Supabase Realtime tiene limitaciones enviando eventos `DELETE` si RLS falla al evaluar datos que ya no existen), la acción de "borrar" ejecuta en realidad un `UPDATE`. La fila no se elimina de la base de datos, sino que su contenido cambia a una frase clave.
- **Seguridad restrictiva (RLS) en el borrado:** Aunque a nivel de código de Flutter hacemos un Soft Delete (UPDATE), la política `messages_delete_sender` que evalúa `using ( sender_id = auth.uid() )` se mantiene en el servidor como medida de seguridad estricta de la base de datos por si en el futuro se requiriese un borrado físico.
- **Matiz en la edición:** la política de UPDATE permite actualizar a ambos
  participantes (necesario para marcar `read_at`), así que la restricción de
  "solo el remitente edita el contenido" NO la garantiza la BD hoy — la aplican
  el filtro del repositorio y la UI (puntos siguientes). Si se quisiera
  garantía a nivel de BD habría que separar `read_at` del `content` (p. ej.
  con una columna/policy específica o un trigger), pendiente de decidir.
- **Defensa en profundidad:** Aunque el servidor (Supabase) ya bloquea accesos indebidos mediante RLS, los métodos del `ChatRepository` en Flutter inyectan de forma forzosa un filtro adicional `.eq('sender_id', _myId)` en las peticiones de `update` y borrado lógico para evitar errores del lado del cliente.
- **Validación visual preventiva:** El detector de gestos (`onLongPress`) se anula de forma condicional desde el propio widget (`(isMine && !isDeleted) ? () => _showMessageOptions() : null`). Esto impide que el usuario pueda interactuar con los mensajes de la otra persona, ni tampoco editar/borrar un mensaje que ya ha sido marcado como eliminado.

**Cómo probarlo a mano:**

> El paso manual que había aquí (crear la política desde el SQL Editor) ya no
> es necesario: la política se aplica con la migración `20260714000018`, que
> ya está en el proyecto remoto desde el 2026-07-14.

1. Iniciar sesión y entrar en la pestaña de Chats.
2. Abrir cualquier conversación existente (o crear una nueva desde una publicación).
3. **Probar bloqueo:** Mantener pulsado de forma prolongada sobre un mensaje recibido (gris). No debe ocurrir nada.
4. **Probar edición:** Mantener pulsado sobre un mensaje propio (color primario). Se abrirá un menú inferior. Seleccionar "Editar", cambiar el texto y pulsar "Guardar". El globo de texto se actualizará en vivo.
5. **Probar borrado:** Mantener pulsado sobre un mensaje propio, seleccionar "Eliminar" en el menú inferior y confirmar en el diálogo rojo. El globo de texto cambiará instantáneamente a "*🚫 Este mensaje ha sido eliminado*" en color gris/cursiva.
6. **Probar bloqueo post-borrado:** Mantener pulsado sobre el mensaje que acabas de eliminar. No debe ocurrir nada ni abrirse el menú.
---

## Moderación (CU-11 Reportar / bloquear)

**Carpeta:** `lib/features/moderation/`

- `domain/report_reasons.dart` — motivos seleccionables (lista acordada:
  Spam, Contenido inapropiado, Acoso, Estafa, Perfil falso, Otro).
- `data/moderation_repository.dart` — `reportAndBlock()` inserta el reporte
  (motivos concatenados en `reports.reason`) y bloquea en la misma acción
  (paso 3 del CU: reportar implica bloquear); el bloqueo usa upsert para que
  re-reportar no falle por la PK compuesta de `blocks`. `fetchMyBlockedIds()`
  se apoya en RLS (cada uno solo ve sus bloqueos). **Sin cambios de BD.**
- `presentation/controllers/report_controller.dart` — `ReportUserController`
  y `blockedUserIdsProvider`, que feed y chat usan para aplicar los efectos.
- `presentation/widgets/report_dialog.dart` — diálogo con checkboxes de
  motivos (exige al menos uno) y botón "Reportar y bloquear".

**Puntos de entrada (paso 1 del CU):** botón de opciones (⋮) en el detalle de
una publicación ajena y en la pantalla de chat.

**Efectos del bloqueo (decisión acordada: ambos):**
- No ves sus publicaciones: el feed las excluye (filtrado en la app, en
  `FeedController._fetchVisible`).
- No puedes chatear con él: la entrada de texto del chat se sustituye por el
  aviso "Has bloqueado a este usuario", y abrir un chat nuevo desde una
  publicación suya se rechaza con ese mismo mensaje.
- Postcondición "aparece como bloqueado": chip "Bloqueado" en la lista de
  chats.

**Nota:** el bloqueo se aplica en la app (no hay políticas RLS que filtren
por `blocks` en el servidor); los reportes quedan con `status = 'pending'`
para el futuro panel de moderación (RF-14, CU-13 a CU-17, no implementado).

**Cómo probarlo a mano** (2 cuentas):
1. Con A, abrir una publicación de B → ⋮ → Reportar → elegir motivos →
   "Reportar y bloquear" → snackbar y la publicación de B desaparece del feed.
2. En Chats, la conversación con B aparece con el chip "Bloqueado"; al
   entrar, no se pueden enviar mensajes.
3. Intentar "Enviar mensaje" en otra publicación de B → "Has bloqueado a
   este usuario."
4. En Supabase, la tabla reports tiene la fila con los motivos y status
   'pending'; blocks tiene la pareja (A, B).

---

## Selector de ciudades con autocompletado (RF-15)

> **Sustituido (2026-07-10):** el autocompletado ya no usa el catálogo en
> memoria sino Google Places — ver la sección "Selector de ciudades con
> Google Places" al final. Se conserva esta sección como historia del modelo
> de datos.

**Modelo de datos (migraciones `20260708000013` y `...014` — las aplica el
usuario, NO están aplicadas al escribir esto):**
- Tabla `cities`: `name` canónico, `normalized_name` (minúsculas sin tildes,
  único), `aliases` normalizados, `is_active` (solo las activas salen en el
  selector). RLS: SELECT para `authenticated`; sin escritura desde el cliente.
  Seed: Vigo (activa), Santiago de Compostela y A Coruña (inactivas, con
  aliases).
- `profiles.city` y `listings.city` (texto) sustituidas por `city_id` (uuid,
  FK → cities, **on delete restrict**: una ciudad referenciada no puede
  borrarse; se retira con `is_active = false`). `listings.city_id` NOT NULL
  (paridad con el esquema anterior); `profiles.city_id` opcional.
- **Backfill**: el texto existente se normaliza con `unaccent`, se busca en
  `cities` por nombre o alias y, si no existe, se crea como ciudad inactiva —
  ninguna fila pierde su ciudad (decisión acordada).

**Cliente (`lib/core/`):**
- `utils/normalize_text.dart` — normalización con el paquete `diacritic`
  (elegido por el usuario frente a una función propia).
- `cities/` — modelo `City`, `CitiesRepository` y `activeCitiesProvider`
  (las activas se cargan UNA vez; filtrado en memoria por pulsación).
- `cities/city_ranking.dart` — ranking puro por niveles (0 exacto, 1 empieza
  por, 2 alguna palabra empieza por, 3 contiene, 4 alias contiene), máximo 8,
  orden por nivel y alfabético dentro del nivel; consulta vacía → activas.
- `widgets/city_selector.dart` — `Autocomplete` de Material con estados de
  carga/error (reintento). Emite siempre la `City` seleccionada (su
  `city_id` es lo que se guarda); al perder el foco, el texto libre se
  descarta o se resuelve si coincide exactamente con una ciudad. El usuario
  nunca puede dejar texto libre como ciudad.

**Puntos sustituidos:** campo Ciudad del perfil (opcional, puede vaciarse),
del formulario de publicación (obligatorio, `validateListingCityId`) y de los
filtros del feed. Los modelos llevan `cityId` + `cityName` (el nombre viene
del join `city:cities(name)` y es solo para mostrar); el feed filtra por
`eq('city_id', ...)`. Las búsquedas recientes guardan `cityId`+`cityName` en
el JSON local; las antiguas (con texto) se leen sin ciudad. El trigger de
registro no escribe ciudad — auth intacta.

**Cómo probarlo a mano** (tras aplicar las migraciones):
1. Perfil → campo Ciudad → con el campo vacío aparece Vigo (única activa);
   escribir "vig" o "Vigo" la sugiere; seleccionarla y guardar.
2. Crear publicación → mismo selector, obligatorio: sin selección aparece
   "Selecciona una ciudad de la lista." y escribir texto libre y salir del
   campo lo descarta.
3. Filtros del feed → seleccionar Vigo filtra; el chip de búsqueda reciente
   muestra "Vigo".
4. Escribir "coruna" o "la coruna" NO sugiere nada (A Coruña está inactiva);
   activarla en BD y reabrir la app la haría aparecer.
   (Nota: desde la migración `20260709000015`, A Coruña y Santiago están
   ACTIVAS y sí aparecen en el selector.)

---

## Selector de barrios con autocompletado

> **Sustituido (2026-07-10):** el barrio y la dirección vienen ahora de Google
> Places y el catálogo `neighborhoods` se retiró — ver la sección "Dirección y
> barrio con Google Places" al final. Se conserva como historia.

**Modelo de datos (migraciones `20260709000015`, `20260709101505` y
`20260709120000` — aplicadas):**
- `20260709000015` activa A Coruña y Santiago de Compostela en el selector.
- `20260709101505` crea `neighborhoods`: catálogo de barrios por ciudad
  (`city_id` FK restrict a `cities`, `name`, `normalized_name` único,
  `aliases` normalizados con variantes gallego/castellano, `is_active`),
  mismas reglas RLS que `cities` (solo SELECT para `authenticated`), y siembra
  23 barrios de A Coruña activos.
- `20260709120000` corrige datos del seed: cinco barrios llevaban
  `normalized_name` con ñ/tildes/mayúsculas (violaba el invariante y los hacía
  inencontrables al buscar sin tildes), un alias de Orzán mal partido, y añade
  el alias "sdc" a Santiago.
- **Decisión de esquema:** `listings.neighborhood` sigue siendo texto (sin
  FK): el selector guarda el nombre canónico del barrio del catálogo. Si en el
  futuro se quiere integridad referencial, habría que añadir
  `neighborhood_id` con su propia migración.
- Nota pendiente: el índice único de `normalized_name` en `neighborhoods` es
  global; si dos ciudades tienen un barrio con el mismo nombre habrá que
  cambiarlo a único por (city_id, normalized_name).

**Cliente (`lib/core/`):**
- `neighborhoods/` — modelo, repositorio + `activeNeighborhoodsProvider`
  (carga única, filtrado en memoria) y ranking idéntico al de ciudades
  (5 niveles, máx. 8, vacío → activos).
- `widgets/neighborhood_selector.dart` — mismo comportamiento que
  `CitySelector` (carga/error, texto libre descartado al perder foco, emite
  siempre la selección) **más filtro por ciudad**: con `cityId` solo ofrece
  los barrios de esa ciudad.

**Puntos sustituidos:** campo Barrio del formulario de publicación
(obligatorio si "tengo piso", opcional/"cualquiera" si "busco") y de los
filtros del feed. En ambos, al cambiar la ciudad se descarta el barrio
seleccionado y el selector se recrea vacío (`ValueKey` por ciudad). El feed
sigue filtrando por `eq('neighborhood', nombre)` — funciona porque siempre se
guarda el nombre canónico.

**Cómo probarlo a mano:**
1. Crear publicación → elegir "A Coruña" → el campo Barrio sugiere los 23
   barrios; escribir "elvina" (sin ñ) encuentra Elviña; "adormideras"
   encuentra Adurmideiras por alias.
2. Cambiar la ciudad a Vigo → el barrio elegido se borra y el selector no
   ofrece ninguno (Vigo no tiene barrios sembrados aún).
3. Filtros del feed → mismo comportamiento; filtrar por Oza muestra solo las
   publicaciones de ese barrio.

## Selector de ciudades con Google Places (RF-15, sustituye al catálogo)

**Decisión:** el autocompletado de ciudad pasa de un catálogo curado a Google
Places Autocomplete (API nueva) restringido a localidades de España. Cualquier
ciudad es seleccionable; el esfuerzo de marketing se concentra en unas pocas
(`cities.is_active` pasa a significar "ciudad foco", ya no limita nada).

**Paquete:** `flutter_google_places_sdk ^0.4.3` con `useNewApi: true` (SDKs
nativos, compatible con la clave restringida a Android). La clave vive en
`.env` como `GOOGLE_PLACES_API_KEY` (no hace falta meta-data en el
AndroidManifest: solo la exige el Maps SDK para renderizar mapas). Coste
controlado con session tokens (nuevo token por sesión de tecleo, cerrado al
seleccionar) y debounce de 350 ms con mínimo de 2 caracteres.

**Modelo de datos (migración `20260710000016` ):**
- `cities.google_place_id` (text, único): nueva identidad canónica.
- `normalized_name` deja de ser único (municipios homónimos en España); su
  índice queda solo para casar filas antiguas.
- RPC `get_or_create_city(place_id, name, normalized_name)` — security
  definer, solo `authenticated`: devuelve la fila por place_id; si no existe,
  reclama una fila antigua sin place_id que case por nombre/alias; si tampoco,
  inserta la ciudad (con `on conflict` para carreras). El cliente sigue sin
  permisos de escritura directa sobre `cities`.

**Cliente (`lib/core/`):**
- `places/places_service.dart` — `PlacesService` (abstracto, falseable en
  tests) + `GooglePlacesService`: autocompletado restringido a `countries:
  ['es']` y `PlaceTypeFilter.CITIES`, gestión del session token, locale es-ES.
- `cities/cities_repository.dart` — `getOrCreateCity()` llama a la RPC; se
  eliminaron `fetchActiveCities`/`activeCitiesProvider` y
  `city_ranking.dart` (muertos tras el cambio).
- `widgets/city_selector.dart` — misma API pública (`onCitySelected(City?)`),
  por lo que perfil, publicación y filtros del feed no cambiaron. Sugerencias
  asíncronas con debounce y descarte de respuestas obsoletas; el desplegable
  muestra la descripción completa ("Toro, Zamora, España") para desambiguar
  homónimos; al elegir se resuelve contra `cities` vía RPC (spinner mientras
  tanto) y se emite la `City` canónica. Texto libre sigue sin contar como
  ciudad (se restaura/descarta al perder el foco).

**Limitación conocida (hasta la fase de dirección con Places):** en una ciudad
recién creada el selector de barrios no ofrece opciones (el catálogo
`neighborhoods` solo tiene A Coruña sembrada), así que una publicación
"ofrezco" fuera de las ciudades sembradas no puede cumplir el barrio
obligatorio. Se resuelve al integrar la dirección/barrio con Places.

**Cómo probarlo a mano:**
1. Crear publicación → escribir "coru" → sugerencias de Google con provincia;
   elegir "A Coruña" → se guarda la misma fila de siempre del catálogo (por
   nombre/alias) y queda ligada a su place_id.
2. Escribir "Madrid" y elegirla → se crea la fila en `cities` al vuelo y la
   publicación la referencia por `city_id`.
3. Filtros del feed → mismo selector; cualquier ciudad de España es filtrable.
4. Sin conexión → el campo muestra "No se pudieron cargar las sugerencias."

## Dirección y barrio con Google Places (CU-06, sustituye al catálogo de barrios)

**Decisión:** la ubicación fina de una publicación (dirección con calle o solo
barrio) viene de Places Autocomplete + Place Details, sesgada a la ciudad
elegida (se añade la ciudad a la consulta; el SDK solo sesga por coordenadas).
El catálogo `neighborhoods` se retiró.

**Privacidad (comentario de CU-06):** el usuario elige con un interruptor si
el anuncio muestra la dirección completa o solo el barrio. La dirección exacta
vive en `listing_addresses` (tabla 1:1 con `listings`) porque RLS es por fila:
si `is_public = false`, la BD no entrega la fila a nadie más que al dueño — la
privacidad no depende del cliente. Si el usuario pone solo el barrio, no hay
fila de dirección y no da error (se muestra el barrio).

**Modelo de datos (migración `20260710000017`):**
- `listing_addresses`: `listing_id` (PK/FK cascade), `formatted_address`,
  `google_place_id`, `latitude`, `longitude`, `is_public`. RLS: SELECT si
  `is_public` o dueño; escritura solo dueño.
- `drop table neighborhoods` — el barrio ya no tiene catálogo.
- `listings.neighborhood` (texto) ahora guarda el barrio que devuelve Places
  (derivado de los address components de la dirección, o el elegido a mano).

**Cliente:**
- `places/places_service.dart` — `autocompleteAddresses(query, cityName,
  neighborhoodsOnly)` (GEOCODE o REGIONS + filtro a barrios) y
  `fetchDetails(placeId)` con field mask mínima (Address, AddressComponents,
  Location, Types); la petición de detalles consume el session token.
- `widgets/address_selector.dart` — nuevo selector compartido: en publicación
  ofrece direcciones y barrios (pide detalles al elegir, deriva el barrio de
  los components); en los filtros (`neighborhoodsOnly`) solo barrios y sin
  petición de detalles (el nombre basta, no factura Details).
- Publicación: `ListingDraft` lleva la dirección estructurada y
  `showExactAddress`; el repositorio hace upsert/delete de
  `listing_addresses` tras crear/editar. El interruptor de privacidad solo
  aparece si la selección es una dirección con calle.
- Feed/detalle: los selects embeben `address:listing_addresses(...)` — RLS
  decide si llega. El detalle muestra `formatted_address` si está disponible
  y si no "barrio, ciudad".
- Validación: `validateListingLocation` (antes `validateListingNeighborhood`):
  obligatoria solo en "ofrezco"; sirve dirección O barrio (CU-06).

**Cómo probarlo a mano:**
1. Crear publicación (ofrezco) → en "Dirección o barrio" escribir una calle →
   elegirla → aparece "Barrio: X" y el interruptor "Mostrar la dirección
   completa" (apagado por defecto).
2. Publicar con el interruptor apagado → el detalle visto por OTRO usuario
   muestra solo "barrio, ciudad"; el dueño sí ve la dirección.
3. Publicar con el interruptor encendido → todos ven la dirección completa.
4. Escribir solo un barrio ("Os Castros") → publica sin error y se muestra el
   barrio (CU-06).
5. Filtros del feed → campo Barrio sugiere barrios de la ciudad elegida;
   filtrar muestra solo publicaciones con ese barrio.
   
## Modo Oscuro / Modo Claro (RF-16)

**Carpeta: lib/core/theme/**

    - core/theme/theme_controller.dart — ThemeController (AsyncNotifier<ThemeMode>). Gestiona la lógica de alternancia y la persistencia local de la preferencia del usuario.

    - core/theme/app_theme.dart — Definiciones de ThemeData (light y dark) utilizando ColorScheme.fromSeed para mantener consistencia con el color primario del proyecto.

    - main.dart — Integración con MaterialApp.themeMode. El widget Room2getherApp escucha al provider para reconstruir el árbol de widgets con el tema correcto.

    - features/profile/presentation/screens/edit_profile_screen.dart — Implementación del SwitchListTile en la pantalla de perfil para la gestión del usuario.

**Decisiones técnicas:**

    - Persistencia local: Se utiliza shared_preferences para almacenar el estado ('light', 'dark' o 'system') en el dispositivo. Al ser una preferencia meramente estética del cliente, se descartó cualquier sincronización con la base de datos (Supabase) para evitar latencia y consumo innecesario de red.

    - Reactividad centralizada: Se utiliza un AsyncNotifier para el estado del tema. Esto permite que MaterialApp.themeMode reaccione instantáneamente ante cualquier cambio de estado (ref.watch(themeControllerProvider)), propagando el cambio a toda la jerarquía de la app sin necesidad de refrescos manuales.

    - Fallback al sistema: Si el usuario no ha realizado ninguna elección previa, el ThemeController devuelve ThemeMode.system, respetando así la configuración de accesibilidad del sistema operativo del usuario.

**Cómo probarlo a mano:**

    - Navegar a la pantalla de "Tu perfil".

    - Localizar el interruptor "Modo Oscuro" (debajo de "Guardar cambios").

    - Activar/Desactivar el interruptor → La interfaz debe cambiar su esquema de colores (fondo y texto) de forma instantánea.

    - Cerrar la aplicación por completo (eliminar de la multitarea) y volver a abrirla → La aplicación debe recordar y aplicar automáticamente la última preferencia elegida (persistencia).
   
