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
- `presentation/screens/{welcome,login,register}_screen.dart`. En escritorio
  (ancho ≥ 840 dp) su contenido se enmarca centrado y con ancho máximo mediante
  `CenteredFormFrame` (`core/widgets/`); en móvil ocupa el ancho completo. No
  hay variante de escritorio: mismo formulario y validación, solo cambia el
  encuadre.
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

## Feed y Selección Inicial (CU-09 Explorar y filtrar el feed)

**Carpeta:** `lib/features/feed/`

- `domain/models/listing.dart` — modelo `Listing` (mapea con la tabla `listings`).
- `domain/models/listing_filter.dart` — criterios de búsqueda: `city`,
  `neighborhood`, `maxPrice`, `type`. Son exactamente los tres que fija RF-06
  ("zona, precio, tipo").
- `data/feed_repository.dart` — `FeedRepository`: `fetchListings(filter)` (solo
  `status = 'active'`, con los filtros aplicados como condiciones adicionales)
  y `fetchListingById(id)` para el detalle.
- `data/recent_searches_repository.dart` — búsquedas recientes guardadas SOLO
  en el dispositivo con `shared_preferences`.
- `presentation/controllers/feed_controller.dart` — `AsyncNotifier<List<Listing>>`;
  carga publicaciones y aplica filtros de búsqueda dinámica.
- `presentation/controllers/listing_detail_controller.dart` — `FutureProvider.family`
  para cargar una publicación por id.
- `presentation/screens/home_selection_screen.dart` — **Nueva pantalla de inicio**. 
  Actúa como raíz de la rama Buscar en el router. Muestra dos tarjetas grandes 
  ("Busco compañero" / "Busco piso") para capturar la intención de búsqueda del usuario antes de cargar la lista.
- `presentation/screens/feed_screen.dart` — pantalla principal de la lista de
  publicaciones. Se refactorizó a `ConsumerStatefulWidget` para inyectar dinámicamente 
  el filtro de tipo (`isLookingForRoommate`) recibido por parámetro. Incluye icono de buscar (abre `FiltersSheet`).
- `presentation/screens/listing_detail_screen.dart` — vista mínima de detalle
  (tipo, título, ubicación, precio, descripción). 
- `presentation/widgets/{listing_card,filters_sheet}.dart`.

**Decisión técnica clave — Enrutado de inicio y paso de parámetros:** 
Se sustituyó `/feed` por `/home` (`HomeSelectionScreen`) como la ruta inicial de la primera rama del `AdaptiveShell` tras iniciar sesión (o al recuperar sesión activa por `supabase_flutter`). La navegación de `/home` a `/feed` **no** se hace instanciando el widget directamente, sino delegando en `go_router` (`context.push('/feed', extra: true/false)`). Esto mantiene la limpieza del árbol de navegación, preserva la barra inferior (BottomNavigationBar) en ambas pantallas y permite volver atrás nativamente.

**Decisión pendiente resuelta — acceso sin sesión:** la precondición de CU-09 es
"N/A" (a diferencia del resto de casos de uso), lo que sugiere que se podría
explorar sin cuenta. Sin embargo hoy las políticas RLS de `listings` solo
permiten `SELECT` al rol `authenticated`. Se decidió **no** tocar RLS por ahora
y exigir sesión igual que el resto de la app.

**Cómo probarlo a mano:**
1. Iniciar sesión o abrir la app con sesión activa → aparece la pantalla de selección `HomeSelectionScreen` ("¿Qué estás buscando?").
2. Tocar "Busco compañero" → navega al feed mostrando solo publicaciones de gente que busca habitación (filtro automático).
3. Deslizar hacia atrás (o botón back) → vuelve a la selección fluida sin perder la barra de navegación.
4. Pulsar el icono de buscar dentro del feed, aplicar un filtro de ciudad/precio/tipo → la
   lista se actualiza y la búsqueda queda guardada como "reciente".
5. Tocar una publicación → se abre el detalle con sus datos.

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
  CU-11). En móvil pinta la lista; en escritorio devuelve un *placeholder*
  porque la lista la pinta el shell (ver más abajo).
- `presentation/widgets/conversations_list_view.dart` — lista de conversaciones
  compartida (estados carga/error/vacío + resaltado del seleccionado);
  `presentation/widgets/conversations_pane.dart` — columna persistente de
  escritorio que la envuelve.
- Entrada del flujo: botón "Enviar mensaje" en el detalle de una publicación
  ajena (paso 2 de CU-10). Rutas `/chats` y `/chats/:id`.

**Layout en escritorio (master-detail):** `/chats` y `/chats/:id` viven en la
rama "Chats" del `StatefulShellRoute`, igual que `/feed` y `/listings/:id` en
Buscar. En web ancha, `DesktopShell` muestra la lista de conversaciones como
columna persistente y el chat (`ChatScreen`) como panel a la derecha, con el
rail y el resto visibles detrás; el chat abierto viaja por la URL. En móvil el
chat es una pantalla de la sección (comparte la barra inferior, como el detalle
de publicación). "Enviar mensaje" desde una publicación cruza de la rama Buscar
a la de Chats con `context.go` (`push` no cruza ramas). Detalle del patrón y
cómo añadir un tercer panel: skill `ui-conventions`.

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

---

## Desbloquear usuarios (CU-11, ampliación)

**Sin migración.** El bloqueo ya lo permitía todo: la tabla `blocks` y su
política `blocks_delete_own` (`blocker_id = auth.uid()`, migración `...006`) ya
dejaban a cada usuario borrar **solo** sus propios bloqueos. Desbloquear es
borrar la fila.

- `domain/models/blocked_user.dart` — id, nombre, avatar y fecha de bloqueo.
- `data/moderation_repository.dart`:
  - `fetchBlockedUsers()` — `blocks` con el perfil embebido
    (`profiles!blocks_blocked_id_fkey`), orden por `created_at` desc.
  - `unblockUser(id)` — `delete().eq('blocker_id', me).eq('blocked_id', id)`.
    RLS ya bastaría; el filtro por `blocker_id` es defensa en profundidad, igual
    que en el chat.
- `presentation/controllers/report_controller.dart` — `blockedUsersProvider` y
  `UnblockUserController`. El controlador **solo** invalida los providers de
  moderación (`myBlocksProvider`, `blockedUsersProvider`); los efectos en feed
  y chat los refresca la pantalla, mismo patrón que el reporte en `ChatScreen`,
  para no acoplar moderación a otras features.
- `presentation/screens/blocked_users_screen.dart` — lista con estados
  carga/error/**vacío** ("No has bloqueado a nadie"), avatar, nombre y
  "Bloqueado el D de MES de AAAA", botón Desbloquear con diálogo de confirmación
  y snackbar. Al desbloquear con éxito invalida `feedControllerProvider`,
  `conversationsProvider` y `unreadCountsProvider`.
- Ruta `/profile/blocked`, **subruta de `/profile`** dentro de la rama Perfil:
  conserva barra inferior en móvil y rail en escritorio. Entrada desde
  `EditProfileScreen`, sección nueva "Cuenta y privacidad".

**Qué se restaura al desbloquear** (todos los efectos de CU-11, en orden
inverso): sus publicaciones vuelven al feed, se le puede volver a escribir y
abrir chat nuevo, sus mensajes dejan de ocultarse (`visibleMessages` ya no
filtra sin `blockedAt`) y vuelven a contar en el badge, y desaparece el chip
"Bloqueado" de la lista de chats.

**Qué NO se toca:** las conversaciones y mensajes previos nunca se borraron con
el bloqueo (solo se ocultaban los posteriores), así que reaparecen intactos —
no hay nada que "restaurar". Y **el reporte (`reports`) no se revierte**:
bloquear y reportar son la misma acción en la UI (CU-11 paso 3), pero el reporte
es material de moderación (`status = 'pending'`, RF-14) y desbloquear es una
decisión personal; borrar la denuncia sería perder señal de moderación. El
bloqueo es unidireccional, así que en la cuenta del otro no hay nada que
cambiar.

**Cómo probarlo a mano** (2 cuentas):
1. Con A, bloquear a B (reportar desde una publicación o chat de B).
2. Perfil → "Cuenta y privacidad" → "Usuarios bloqueados": aparece B con su
   foto, nombre y fecha.
3. "Desbloquear" → confirmar → snackbar y B desaparece de la lista.
4. El feed vuelve a mostrar las publicaciones de B; el chat con B permite
   escribir de nuevo y sus mensajes reaparecen; el chip "Bloqueado" desaparece.
5. En Supabase, la fila de `blocks` (A, B) ya no está; la de `reports` sigue.

---

## Mensajes sin leer: badge en la navegación (CU-10, ampliación)

**Migración:** `supabase/migrations/20260724000019_messages_unread.sql`.

**Sin esquema nuevo.** `messages.read_at` ya existía desde la migración
original pero **nadie lo escribía nunca**: el modelo `Message` lo leía y siempre
valía `null`. "Sin leer" es `read_at is null and sender_id <> auth.uid()` dentro
de mis conversaciones. La migración solo añade un índice parcial, dos funciones
y el endurecimiento de una política.

### Endurecimiento de RLS (deuda que estaba anotada aquí)

`messages_update_participants` dejaba a **cualquiera de los dos** participantes
actualizar **cualquier columna** de **cualquier mensaje** del hilo, incluido el
`content` del otro. Existía así porque marcar `read_at` obliga a tocar los
mensajes recibidos y RLS no distingue columnas; lo único que lo frenaba era el
filtro `.eq('sender_id', ...)` del cliente, que es una cortesía, no una
garantía. Ahora:

- `messages_update_own` — UPDATE solo si `sender_id = auth.uid()`. Cubre editar
  y el borrado lógico, que ya filtraban por remitente en el cliente.
- `mark_conversation_read(uuid)` — `security definer`, valida que quien llama
  participa y solo escribe `read_at` en los mensajes recibidos.

### Contador

- `unread_counts()` — `security invoker`, así que RLS sigue aplicando y solo
  cuenta lo de mis conversaciones. **Excluye a los bloqueados**: si has
  bloqueado a alguien, sus mensajes no te hacen sonar el badge, coherente con
  el resto de efectos de CU-11. Que el filtro esté en SQL no cambia la decisión
  de aplicar el bloqueo en la app: esto es una consulta nuestra, no una
  política.
- `ChatRepository.watchInboxChanges()` — canal Realtime de **señal**, no un
  `stream()` de mensajes. Suscribirse a todos mis mensajes para contarlos
  significaría descargarlos y mantenerlos en memoria mientras la app esté
  abierta; aquí solo llega el aviso (INSERT y UPDATE) y el número sale de la
  consulta agregada.
- `unreadCountsProvider` (StreamProvider) emite el conteo inicial y lo recalcula
  con cada señal; `totalUnreadProvider` suma. Mientras carga o falla vale 0: un
  badge es información secundaria y no debe pintar nada sin un número real.

### Badge, una sola vez para las dos formas

`ShellDestination` gana `showsUnreadBadge` (solo Chats) y
`core/layout/shell_destination_icon.dart` pinta el icono con su `Badge`.
`MobileShell` y `DesktopShell` usan ese widget en vez de `Icon`, así que la
barra y el rail comparten la lógica: no hay dos implementaciones que puedan
divergir. El número exacto llega hasta `kUnreadBadgeMax` (99) y por encima se
corta en "99+".

En la lista de chats, cada conversación muestra su propio contador y el nombre
en negrita. Ambos badges llevan `Semantics` con "N mensajes sin leer": el número
suelto no dice nada a un lector de pantalla.

### Marcar como leído

`ChatScreen` llama a `markConversationRead` al entrar, al cambiar de
conversación en el panel de escritorio (`didUpdateWidget`, porque ahí la
pantalla se reutiliza sin reconstruirse) y cada vez que llega un mensaje con el
chat abierto — si no, el badge subiría mientras lo estás mirando. El UPDATE
viaja por el mismo canal, así que el contador se recalcula solo, sin
`invalidate` manual. Si falla, se ignora: es un efecto secundario y el usuario
puede seguir leyendo y escribiendo.

### Bloqueo y mensajes

`visibleMessages()` (`features/chat/domain/message_visibility.dart`, función
pura y testeada) oculta lo que un usuario bloqueado escriba **a partir del
bloqueo**. Se filtra por fecha, no de golpe: la conversación anterior sigue
teniendo sentido, y así desbloquear no tiene que restaurar nada, solo deja de
filtrar. Los mensajes propios nunca se ocultan. Para esto hacía falta la fecha
del bloqueo, así que `ModerationRepository` gana `fetchMyBlocks()`
(id → `created_at`) y `blockedUserIdsProvider` pasa a derivarse de
`myBlocksProvider`, sin consultas extra.

**Cómo probarlo a mano** (2 cuentas):
1. Con B, escribir a A. En A, el icono de Chats debe estrenar badge **sin
   recargar** (Realtime), y la conversación debe aparecer en negrita con su
   número.
2. En A, abrir esa conversación → el badge desaparece. Cerrarla y volver: sigue
   sin badge.
3. Con el chat abierto en A, escribir desde B → el mensaje aparece y el badge
   **no** sube.
4. Enviar 100+ mensajes desde B sin abrir → el badge muestra "99+".
5. En escritorio (web ancha), lo mismo: el badge sale en el rail y cambiar de
   conversación en el panel marca como leída la nueva.
6. Bloquear a B desde el chat → sus mensajes anteriores siguen visibles, los
   nuevos no aparecen y no suben el badge.
7. En Supabase, `select * from messages where read_at is not null` tras abrir
   una conversación; y comprobar que un participante **no** puede editar el
   `content` de un mensaje ajeno (la política ya no lo permite).

---

## Foto de perfil: refresco y recorte (CU-04, revisión)

Dos cosas en un mismo flujo: arreglar que la foto nueva no se viera y añadir el
recorte previo. **Sin cambios de BD ni de políticas de Storage.**

### El bug de refresco

`SupabaseProfileRepository.uploadAvatar` subía siempre a la **misma ruta**,
`{userId}/avatar.{ext}` con `upsert: true`. Al sobrescribir el fichero,
`getPublicUrl()` devolvía una URL idéntica, así que:

1. el `ImageCache` de Flutter, que indexa por URL, seguía sirviendo los bytes
   viejos a `NetworkImage`;
2. en web, además, la respuesta anterior estaba en la caché HTTP del navegador
   (Storage sirve `cache-control: max-age=3600`);
3. y el `setState` de la pantalla asignaba la misma cadena, así que ni siquiera
   cambiaba la identidad del widget de imagen.

El estado de Riverpod **sí** se actualizaba: `ProfileController.uploadAvatar` ya
hacía `state = AsyncData(updated)`. El fallo era de identidad de URL, no de
gestión de estado. Por eso "funcionaba" al cambiar de `.jpg` a `.png`.

**Arreglo:** ruta única por subida,
`{userId}/{microsegundos}.jpg`, igual que ya hacía `uploadPhotos` con las fotos
de publicación. URL nueva ⇒ no hay caché que invalidar, ni la propia ni la de
los demás usuarios que ven tu avatar en la lista de chats. Se descartó evictar
del `ImageCache`: arregla Flutter pero no el navegador ni los otros clientes.

La foto anterior se borra del bucket (política `avatars_delete_own`, ya
existente) en modo *best effort*: si el borrado falla, la subida sigue siendo
válida. `avatarStoragePathFromUrl()` deriva la ruta a borrar desde la URL
guardada y devuelve `null` si esa URL no es del bucket `avatars` o no está
dentro de la carpeta del propio usuario, de modo que un `avatar_url` inesperado
nunca puede apuntar el borrado a la carpeta de otra persona.

### El recorte

- `features/profile/presentation/widgets/avatar_cropper_screen.dart` — pantalla
  de recorte a pantalla completa (`showAvatarCropper()` devuelve los bytes o
  `null` si se cancela). Marco **fijo** 1:1 con máscara circular; la imagen se
  mueve y se amplía con dos dedos o con la rueda del ratón
  (`interactive: true`, `fixCropRect: true`), como en WhatsApp o Instagram.

  **Salida garantizada:** si a los 12 s el recortador no ha llegado a
  `CropStatus.ready` (o el recorte falla, o tampoco vuelve tras confirmar),
  aparece un `MaterialBanner` con "Usar recortada al centro", que resuelve el
  recorte con `cropSquareCenterAndEncodeJpeg()` — tubería propia, sin pasar por
  `crop_your_image`. El requisito es que el usuario pueda usar **cualquier**
  foto de su dispositivo; el recorte a mano es lo deseable, no lo obligatorio.
- `core/utils/image_processing.dart` — dos pasos:
  - `core/utils/image_downscaler.dart` (+ `_stub` / `_web`) — import
    condicional, mismo patrón que `link_opener`. En web reduce la foto con el
    **pipeline del propio navegador** (`<img>` + `canvas` + `toDataURL`); fuera
    de web devuelve `null` y no se usa.

    **Por qué existe:** en web `dart:ui` decodifica dentro del heap de
    WebAssembly, y una foto de móvil (12 MP, varios MB) puede no caber. El
    síntoma es "no se puede abrir esta imagen" **a cualquier tamaño de
    destino**, porque el coste está en decodificar el original, no en producir
    el resultado. Por eso la escalera de tamaños no arreglaba este caso: cada
    peldaño repetía la misma decodificación cara. El navegador, en cambio,
    decodifica imágenes grandes en su pipeline nativo sin ese techo.

    Usa `toDataURL` y no `toBlob` deliberadamente: `toBlob` entrega por
    callback y el navegador le pasa `null` cuando no puede producir el
    resultado, dejando colgado a quien lo espere — es exactamente el fallo de
    `image_picker_for_web` descrito más abajo.

  - `normalizeForCrop()` prepara la foto **antes** de abrir el recortador.
    Decodifica con `dart:ui` (el decodificador del navegador en web, Skia en
    Android), reescala al vuelo y recodifica en JPEG. Si un tamaño falla **o
    tarda más de `kAvatarNormalizeTimeout`**, reintenta con el siguiente de
    `kAvatarNormalizeSides` (1024 → 768 → 512 → 384 → 256) antes de rendirse.
    El límite de arriba es 1024 porque el avatar acaba en `kAvatarMaxSide`
    (512) pase lo que pase: pedir más es trabajo que se tira, y lo paga el
    hilo principal del navegador. El de abajo es 256 porque más vale una foto
    algo menos nítida que no poder ponerla. Si fallan los cinco, queda un
    último recurso que decodifica con el paquete `image` (más lento y con
    menos formatos, pero independiente de `dart:ui`).

    **`targetWidth`/`targetHeight` son una petición, no una garantía:** no
    todos los códecs los respetan, y en web depende del navegador. Si el códec
    los ignora, la imagen sale a tamaño completo y leerla en RGBA son decenas
    de MB que después hay que recomprimir en Dart — que es exactamente cómo se
    rompió esto una vez. Por eso, si las dimensiones no coinciden con lo
    pedido, `_scaleImage()` la redibuja con `PictureRecorder` (escalado del
    motor de pintado, no de Dart) antes de leer un solo byte.

  Cuando la normalización se rinde, el SnackBar incluye **el tamaño del fichero
  y el tipo del primer error**. Es feo a propósito: esto se prueba en el
  navegador de un móvil, donde no hay consola a mano. Se puede quitar cuando la
  feature lleve un tiempo estable.
  - `resizeAndEncodeJpeg()` (función pura, testeada) deja el recorte final en
    **512 px** y **JPEG calidad 85**; `resizeAvatarBytes()` la lanza con
    `compute`. Un fichero corrupto devuelve `null` en vez de propagar la
    excepción del decodificador.

  **Por qué hace falta normalizar:** `crop_your_image` decodifica con el
  paquete `image`, en Dart. Eso significa que (a) no entiende HEIC ni todos los
  WebP, y una foto en esos formatos deja el recortador cargando
  indefinidamente, y (b) en web **no hay isolates**, así que decodificar una
  imagen grande congela el hilo principal. Delegar el decode en la plataforma
  resuelve las dos cosas: abre todo lo que el sistema sabe abrir y entrega al
  recortador un JPEG pequeño. Se detectó probando en el navegador del móvil,
  donde con algunas fotos el recorte no llegaba a aparecer.
- `edit_profile_screen.dart` — hoja inferior **Galería / Cámara** (antes solo
  había galería) → `image_picker` → normalización → recorte → compresión →
  subida. Cada paso que puede fallar muestra un SnackBar distinto ("no se pudo
  leer" / "abrir" / "procesar" / "subir"), para que un fallo se pueda situar
  sin depurar.

  A `pickImage()` **no** se le pasan `maxWidth`/`maxHeight`/`imageQuality`, y
  esto no es cosmético: en web esas opciones activan el redimensionado de
  `image_picker_for_web`, que dibuja en un `canvas` y completa su `Completer`
  dentro del callback de `canvas.toBlob`. Cuando el navegador pasa `null` a ese
  callback —lo que hace justo cuando el canvas supera su límite de tamaño, en
  torno a los 16 M de píxeles en iOS Safari— **el `Completer` no se completa
  nunca y `pickImage()` se queda colgado para siempre**. No hay forma de
  detectarlo desde fuera: no lanza, no vuelve. De reescalar se encarga
  `normalizeForCrop`, que no pasa por canvas.

**Tamaño elegido (512 px):** el avatar se pinta con `radius: 48` (96 dp), que a
3x de densidad son 288 px reales; 512 deja margen para una futura cabecera de
perfil más grande y pesa ~40–70 KB, frente a los ~250 KB que se subían antes.

**Dependencias nuevas:** `crop_your_image` (UI de recorte) e `image`
(redimensionado y codificación JPEG; ya era dependencia transitiva). Se eligieron
por ser **Dart/Flutter puro**: el mismo código vale para Android y para web sin
condicionales de plataforma. La alternativa habitual, `image_cropper`, exige
actividad nativa en Android *y* cargar `cropperjs` por `<script>` en
`web/index.html`: dos implementaciones distintas más una dependencia externa.

**Nota sobre la cámara en web:** en navegador de escritorio no hay cámara y
`image_picker` abre el selector de archivos; en navegador móvil sí abre la
cámara. Es comportamiento del paquete, no una decisión de layout.

**Cómo probarlo a mano:**
1. Perfil → icono de cámara sobre el avatar → "Elegir de la galería".
2. Ampliar con dos dedos (o rueda) y arrastrar para encuadrar → "Cancelar" no
   cambia nada; "Confirmar" sube la foto.
3. **La foto nueva debe verse inmediatamente**, sin reiniciar la app. Repetir el
   cambio 2–3 seguidas: cada una debe verse al instante.
4. En Supabase → Storage → `avatars` → carpeta del usuario: debe quedar **un
   solo fichero**, el último (los anteriores se borran).
5. Repetir el punto 1 con "Hacer una foto" en Android.
6. En web (`flutter run -d chrome`), repetir 1–3: mismo comportamiento, y la
   foto nueva se ve sin forzar recarga del navegador.
7. Salir del perfil sin pulsar "Guardar cambios" y volver a entrar → la foto
   sigue siendo la nueva (se persiste en el momento de subir).
8. **En el navegador del móvil**, probar con varias fotos distintas de la
   galería, incluidas capturas de pantalla y fotos recientes de la cámara: el
   recorte debe abrirse en todas. Con una que no se pueda abrir debe salir
   "No se pudo abrir esa foto", nunca quedarse cargando.

### HEIC en web: limitación conocida (confirmada 2026-07-24)

Las fotos hechas con un iPhone son **HEIC**, y **ningún navegador de Android ni
de escritorio sabe decodificarlas** (solo Safari). Tampoco CanvasKit ni el
paquete `image`. Al compartirlas, algunas apps las renombran a `.jpg` y las
anuncian como `image/jpeg`, así que **la extensión y el MIME mienten**: el
único dato fiable es la cabecera del fichero, que es lo que lee
`describeImageBytes()` (`ISOBMFF/heic`).

Diagnóstico real de un caso: `jpg · image/jpeg · real:ISOBMFF/heic ·
leídos:86KB/declarados:86KB`. Fíjate en el tamaño: 86 KB. **No es un problema
de peso**, y perseguirlo como tal costó varios intentos — la escalera de
tamaños de `normalizeForCrop` no sirve para este caso y no hay que confundirla
con él.

**Solo afecta a la web.** En la app Android, `dart:ui` decodifica con Skia, que
sí entiende HEIC desde Android 8.

**Solución (decidida 2026-07-24): decodificador bajo demanda.**
`core/utils/heic_decoder.dart` (+ `_stub` / `_web`, import condicional) inyecta
`web/heic/heic2any.min.js` —~1,3 MB, versionado en el repo, servido desde el
propio sitio— **la primera vez que alguien elige una foto HEIC**, y convierte a
JPEG antes de que arranque la tubería normal. Descartadas: conversión en el
servidor (añade una Edge Function que mantener) y dejarlo sin resolver (el
requisito es que se pueda usar cualquier foto del dispositivo).

Detalles que importan:

- **La decisión se toma por la cabecera** (`isHeicContainer`), nunca por la
  extensión ni el MIME. En el caso real, el fichero se llamaba `.jpg` y se
  anunciaba como `image/jpeg` siendo HEIC.
- **No se precarga.** El `CORE` del service worker generado solo incluye
  `main.dart.js`, `index.html`, `flutter_bootstrap.js` y dos manifiestos; el
  decodificador queda en `RESOURCES`, que se cachea al pedirlo. Quien suba un
  JPEG no descarga nada de esto. Si se añade al `CORE`, se pierde la única
  razón por la que este montaje merece la pena.
- **Degrada bien.** Si el fichero falta o su carga falla, `decodeHeicToJpeg`
  devuelve `null` y la app se comporta como antes, con su mensaje de error.

> **Ojo al probar en web:** la app registra un *service worker*, así que un
> navegador que ya había visitado room2gether.com sirve la versión cacheada en
> esa visita y solo estrena la nueva en la siguiente. Si un cambio "no aparece"
> en el móvil, recarga dos veces o prueba en una pestaña privada antes de
> buscar el fallo en el código.

---

## Buscador de usuarios (CU-20, RF-19)

**Migración:** `supabase/migrations/20260804000020_user_search.sql`.

Búsqueda por `display_name`, parcial, insensible a mayúsculas y a tildes,
conforme se teclea.

**Por qué una RPC y no un `select` desde el cliente.** Dos razones, ninguna
opcional:

1. **El bloqueo en sentido inverso.** `blocks_select_own` solo deja ver los
   bloqueos propios, así que el cliente puede saber a quién ha bloqueado él,
   pero **no quién le ha bloqueado a él**. Excluir ambos sentidos exige
   `security definer`.
2. **El coste.** Traerse perfiles y descartarlos en Dart rompe el `limit` y
   obliga a escanear la tabla entera.

`search_profiles(p_query, p_limit, p_offset)` es `security definer` pero **no
amplía lo visible**: `profiles_select_authenticated` ya permite leer cualquier
perfil a quien tenga sesión, y la función devuelve menos filas (excluye
bloqueados y al propio usuario) y menos columnas que un `select` directo. El
`limit` va acotado dentro (`least(greatest(...), 50)`): un cliente manipulado
no puede pedir la tabla entera.

**Índice.** `ilike '%texto%'` no puede usar un B-tree (no hay prefijo por el
que arrancar), así que va un GIN de trigramas (`pg_trgm`). Como la búsqueda es
insensible a tildes hace falta `unaccent`, que se declara `STABLE` y por tanto
**no es indexable**; de ahí el envoltorio `immutable_unaccent()`. El índice va
sobre **esa misma expresión** que usa la consulta — si no coincidiera
exactamente, el planificador no lo usaría.

**Escapado.** `%` y `_` son comodines de `LIKE`: el texto del usuario se escapa
antes de entrar en la consulta. Sin ello, escribir `%` devolvería a todos los
usuarios de la plataforma. El mínimo de 2 caracteres se mide sobre el texto
crudo, no sobre el escapado, que es más largo.

- `domain/models/user_search_result.dart` — id, nombre, avatar y ciudad. Más
  pequeño que `Profile` a propósito: es lo que se pinta en una fila.
- `data/user_search_repository.dart` — la RPC.
- `presentation/controllers/user_search_controller.dart` — estado plano
  (`UserSearchState`) en vez de `AsyncValue`: al teclear interesa **seguir
  viendo los resultados anteriores** mientras llega la respuesta nueva, no
  vaciar la lista en cada pulsación. Debounce de 350 ms y un contador
  `_searchId` que hace dos cosas a la vez: cancela el debounce al seguir
  tecleando y descarta la respuesta de una petición en vuelo que ya no
  corresponde a lo escrito (sin él, una consulta lenta aterriza después de otra
  más reciente y pisa la lista). Mismo patrón que `CitySelector`.
- `presentation/widgets/user_search_results.dart` — widget de contenido
  compartido, con los cuatro estados: inicial, cargando, sin resultados y
  error. Paginación de 20 al llegar al final de la lista.
- `presentation/screens/user_search_screen.dart` — campo de búsqueda en la
  `AppBar`, con autofoco y botón de limpiar.
- Ruta `/users/search`, **raíz, fuera del shell**: es una tarea puntual que se
  abre y se cierra con la flecha de volver, no una sección. Encuadrada con
  `CenteredPageFrame` como toda ruta raíz.

---

## Ver perfil de otro usuario (CU-19, RF-20)

**Migración:** `supabase/migrations/20260804000021_public_profile.sql`.

`get_public_profile(p_user_id)` devuelve **los campos que su dueño puede
cambiar en la pestaña Perfil**: nombre, foto, bio, ciudad, presupuesto y
preferencias de convivencia. Quedan fuera `birthdate` (dato personal que nadie
edita), `role` e `is_verified`, que gestiona el servidor.

**Por qué la decisión se toma en la base de datos.** Igual que en el buscador,
si te han bloqueado a ti el cliente no puede saberlo. Y como
`profiles_select_authenticated` deja leer cualquier perfil, esconder los datos
en la app sería teatro: la fila viajaría igual. Con bloqueo en **cualquiera de
los dos sentidos** la RPC devuelve la fila con todos los campos a `null` y solo
las banderas `is_visible` / `is_blocked_by_me` — la pantalla necesita saber que
el usuario existe y si el bloqueo es suyo (para ofrecer desbloquear) sin
recibir ni un dato del perfil.

- `domain/models/public_profile.dart` — todos los campos opcionales, porque con
  bloqueo vienen vacíos y eso es un estado legítimo de la pantalla, no un error.
- `data/public_profile_repository.dart` — la RPC.
- `data/feed_repository.dart` — `fetchListingsByOwner(ownerId)`, solo las
  **activas**: las cerradas son asunto de su dueño. Solo se consulta si el
  perfil es visible.
- `data/moderation_repository.dart` — `blockUser(id)`, bloqueo suelto. Existe
  porque hasta ahora solo había la acción combinada de CU-11. **Reportar sigue
  bloqueando** (CU-11 paso 3), y por eso en el menú se llama "Reportar y
  bloquear" y no "Reportar": la etiqueta dice lo que hace.
- `presentation/screens/user_profile_screen.dart` — datos, publicaciones
  activas, botón "Enviar mensaje" (abre chat sin `listingId`, `go` para cruzar
  a la rama Chats) y menú de tres puntos: *Desbloquear* si el bloqueo es tuyo,
  y *Bloquear* / *Reportar y bloquear* si no.
- Ruta `/users/:id`, raíz, **declarada después de `/users/search`** para que
  `search` no se capture como si fuera un id.

**Entradas al perfil** (los dos pasos que enumera CU-19): desde un resultado
del buscador, y desde el nombre del autor en el detalle de una publicación, que
antes era texto inerte.

**Ojo con `AsyncValue.value`:** relanza el error cuando el estado es
`AsyncError`. Usar `valueOrNull` cuando solo se quiere "el valor si lo hay";
con `value`, un fallo de carga hace que reviente el `build` y el estado de
error que la pantalla tiene escrito no llega a pintarse nunca.

---

## Buscador y filtros: cambio de disparadores (CU-20, ampliación)

**Sin migración.** Solo cambia quién abre qué; el panel de filtros
(`FiltersPanel`, `FiltersSheet`) y su lógica no se tocan.

- **La lupa de la `AppBar`** deja de abrir los filtros y pasa a ser la entrada
  al buscador de usuarios. Su etiqueta cambia con ella: `'Buscar'` →
  `'Buscar usuarios'`.
- **Los filtros** pasan a un botón hamburguesa abajo a la izquierda, que abre
  exactamente el mismo `FiltersSheet`.
- **En escritorio** la lupa vive en la cabecera del `DesktopShell`, junto a
  "Publicar": no es una sección con estado propio, así que no entra en el rail.
  El botón hamburguesa **no existe** en escritorio, donde los filtros ya son
  columna persistente. Sale gratis y sin comprobar plataforma: `FeedScreen` ya
  devolvía el placeholder antes de construir su `Scaffold` cuando el ancho es
  de escritorio.

Detalles que importan:

- **Dos FAB en la misma ruta necesitan `heroTag` explícito**, o Flutter lanza
  conflicto de `Hero` con la etiqueta por defecto.
- Los dos botones van en un `Row` **dentro del hueco del FAB** con
  `centerFloat`, en vez de posicionarlos a mano, para que el `Scaffold` siga
  encargándose de separarlos de la `NavigationBar` inferior y del área segura.
- **El botón de filtros se aparta al bajar** por la lista y vuelve al subir
  (`UserScrollNotification`). Mientras está oculto queda **sin acción**, para
  que no se pueda pulsar a ciegas. El de publicar no se mueve.
- **Badge de filtros activos**: un punto, sin número. Se apoya en
  `ListingFilter.isEmpty`, que ya deja fuera `cityName` por ser presentación y
  no criterio (por eso tampoco entra en su igualdad). El punto solo se percibe
  visualmente, así que el botón lleva además un `Semantics` con el estado.


---

## Botón atrás en móvil: historial de pestañas

**Sin migración.** Solo navegación.

El botón atrás del sistema ya no cierra la app a la primera: recorre las
pestañas visitadas.

- `core/layout/tab_history_controller.dart` — `TabHistory`, pila de índices de
  pestaña, y el helper `goToPreviousTab`. Vive fuera del shell porque lo
  consultan dos sitios: el `MobileShell` (botón del sistema) y la flecha de la
  lista de Chats. La pila tiene tope (20): sin él, alternar entre dos secciones
  un rato haría falta un rosario de pulsaciones para llegar al feed.
- `core/layout/mobile_shell.dart` — pasa a `ConsumerStatefulWidget` con un
  `PopScope(canPop: false)`. **Que esto viva en `MobileShell` y no en el
  `AdaptiveShell` es la clave de que quede acotado al ancho de móvil sin
  preguntar por la plataforma**: ese widget solo se construye por debajo del
  breakpoint. Cero `kIsWeb`, cero `Platform`.

Orden de decisión al pulsar atrás:

1. **¿Hay pestaña anterior?** Se vuelve a ella.
2. **¿Estamos fuera del feed sin historial?** (la app arrancó ahí, p. ej. desde
   una notificación) Se va al feed.
3. **En el feed:** la primera pulsación **recarga** el feed y avisa con "Pulsa
   otra vez para salir"; una segunda dentro de 2 s cierra la app
   (`SystemNavigator.pop`). Pasados los 2 s, vuelve a recargar.

Detalles que importan:

- **Las pantallas apiladas dentro de una rama no llegan al `PopScope`**: las
  cierra antes el navegador de su propia rama. Abrir el detalle de una
  publicación y pulsar atrás vuelve a la lista, como siempre. Hay test.
- `goToPreviousTab` recibe `currentIndex` y `goBranch` sueltos, no el shell,
  porque sus dos llamantes lo tienen en formas sin interfaz común:
  `MobileShell` maneja el widget `StatefulNavigationShell` y la lista de Chats,
  que está por debajo, solo alcanza su `State` con `of(context)`.
- El apunte en el historial va en un **post-frame**: tocar un provider durante
  el build dispara "setState during build" en quien lo escuche.
- Volver a una pestaña **no la re-apila**: `visit` ignora la que ya está
  arriba, así que el paso atrás no se deshace solo.

**Refresco del feed.** `FeedController.refresh()` repite la consulta con el
filtro puesto y **no pasa por `AsyncLoading`**: quien refresca ya enseña su
indicador y vaciar la lista daría un parpadeo. Tampoco toca las búsquedas
recientes, que refrescar no es buscar. Lo usan el botón atrás y el
`RefreshIndicator` de `ListingListView` (tirar hacia abajo), que envuelve
también al estado vacío —con `AlwaysScrollableScrollPhysics`, que si no no hay
nada que tirar— porque es justo cuando más apetece reintentar.

**En web estrecha esto también aplica**, porque la forma móvil es la misma. Es
decisión consciente: la alternativa era un tercer `kIsWeb`.


---

## Flecha de volver al entrar en un chat desde fuera de la rama

**Sin migración.** Un cambio de una línea en el router, con un porqué que
conviene no olvidar.

`/chats/:id` estaba declarada como **hermana** de `/chats` dentro de la rama
Chats. Entrar en un chat desde fuera de esa rama (perfil de un usuario, detalle
de una publicación) se hace con `context.go`, y `go` reconstruye la pila de la
rama a partir de la jerarquía de rutas: siendo hermanas, la pila quedaba con el
chat como **única** ruta, no había nada que desapilar y por eso no aparecía la
flecha de volver.

Arreglado pasándola a **subruta** (`path: ':id'` dentro de `/chats`), igual que
`/profile/blocked`. Ahora `go` deja la lista de conversaciones debajo y la
flecha sale sola. La URL no cambia.

Afectaba a las dos entradas, no solo al perfil.

> **Al escribir tests de chat:** la pantalla no llega nunca a reposo (stream de
> realtime), así que `pumpAndSettle` se cuelga. Hay que usar `pump()` seguido
> de `pump(const Duration(seconds: 1))`.

---

## Sección del feed: "Inicio" con casa, en vez de "Buscar" con lupa

La lupa pasó a significar "buscar usuarios" (CU-20), así que tenerla también
como icono de la sección del feed era ambiguo, y la etiqueta "Buscar" lo era
todavía más. El feed se queda con la casa (`Icons.home_outlined` /
`Icons.home`) y la etiqueta **Inicio**, en
`core/layout/shell_destinations.dart`, que es la única fuente de verdad para la
barra inferior y el rail a la vez.

---

## Volver del chat al perfil desde el que se abrió

Entrar en un chat desde el perfil de alguien y que la flecha lleve a la lista
de conversaciones es aterrizar en una pantalla que no se ha visto en todo el
recorrido. `ChatScreen` acepta un `backLocation` opcional:

- Viaja por el **`extra` del router**, no por la URL: así no acaba el id de
  nadie en la barra de direcciones. El precio, asumido: en web se pierde al
  recargar la página, y entonces la flecha vuelve a llevar a la lista.
- `UserProfileScreen` lo manda al contactar
  (`context.go('/chats/<id>', extra: '/users/<userId>')`).
- Con `backLocation` puesto, la pantalla envuelve su `Scaffold` en un
  `PopScope` **además** de poner el `leading`: si no, la flecha llevaría al
  perfil y el botón atrás del sistema a la lista de chats. Dos caminos, un
  destino.
- Desde el detalle de una publicación **no** se manda: allí la lista de chats
  sigue siendo el destino de siempre.


---

## Buscador: coincidencias parecidas (CU-20, ampliación)

**Migración:** `supabase/migrations/20260804000022_user_search_fuzzy.sql`.

La coincidencia por subcadena ya existía desde el principio (`ilike
'%texto%'`): buscar "juan" siempre encontró "angeljuan". Lo que se añade es
tolerancia a **erratas**, como segunda rama en OR: `word_similarity` de
`pg_trgm` con umbral 0.4.

- Se usa `word_similarity` y no `similarity` porque compara lo escrito con el
  **trozo** que mejor encaja del nombre, no con el nombre entero.
- Se compara con la **función** y no con el operador `<%`, aunque el operador
  sí usaría el índice: `<%` lee su umbral de
  `pg_trgm.word_similarity_threshold`, y en Supabase el rol de las migraciones
  **no tiene permiso** para fijar ese parámetro dentro de una función
  (`permission denied to set parameter`). Con la función el umbral queda
  escrito en el código, que además hace el resultado independiente de la
  sesión que llame.
- **Orden:** primero lo literal (empieza por / contiene) y después lo parecido,
  de más a menos. Una aproximación nunca se cuela por delante de una
  coincidencia exacta.

**Coste, y es un compromiso consciente:** `word_similarity` no puede usar el
índice GIN, así que la rama difusa recorre la tabla. Con el volumen de una sola
ciudad da igual. Cuando `profiles` crezca de verdad habrá que revisarlo; lo
natural sería no calcular la rama difusa salvo que la literal devuelva poco.

**Límite conocido:** los trigramas son implacables con las palabras cortas. Un
cambio de vocal en una palabra de cuatro letras ("joan" contra "juan") deja el
parecido en ~0.25, por debajo de cualquier umbral usable — con 5 trigramas por
lado y solo 2 en común. Para cubrir ese caso haría falta comparación
**fonética** (`metaphone` de `fuzzystrmatch`, que descarta las vocales), no
trigramas. Decisión pendiente.

---

## Flechas de volver: una sola pieza para todas las pantallas

`UserProfileScreen` monta su `BackButton` **a mano** en vez de dejar la flecha
automática, con un recambio a `/feed` cuando no hay nada que desapilar.

El motivo: al volver del chat se llega al perfil con `go`, que reemplaza la
pila. La flecha automática, que depende de que haya algo debajo, desaparecía.

Y el chat se abre con `go` y no con `push` por una razón dura: `/users/:id` es
ruta **raíz** y el chat vive dentro del shell. Un `push` apila la página del
shell encima de una ruta raíz cuando esa misma página ya está debajo en la
pila, y el `Navigator` aborta con *"Failed assertion: !keyReservation.contains
(key)"* — claves de página duplicadas. No es una preferencia de estilo: `push`
ahí no compila en tiempo de ejecución.

**Efecto secundario asumido:** después de volver del chat, la flecha del perfil
lleva al feed y no al buscador desde el que se entró. Recuperar ese eslabón
exigiría encadenar el origen a través del chat.


`core/widgets/app_back_button.dart` reúne las tres piezas, para no repetir la
misma lógica en cada pantalla:

- `goBackFrom(context, backLocation:)` — resuelve el atrás en este orden:
  el origen que le dieron, desapilar, y el feed como último recurso.
- `AppBackButton` — la flecha. **Siempre visible**; se usa donde la pantalla
  ocupa todo (perfil de otro usuario).
- `AppBackButton.maybe(context, backLocation:)` — devuelve `null` si no hay
  origen ni nada que desapilar. Es la que va en las pantallas que **también se
  pintan como panel de detalle en escritorio** (publicación, chat): allí la
  lista está en la columna de al lado y una flecha que saltara al feed no
  tendría sentido. Reproduce la flecha automática de siempre, más el caso de
  `backLocation`.
- `BackDestination` — envuelve el `Scaffold` con un `PopScope` cuando hay
  `backLocation`, para que el botón atrás del sistema acabe donde la flecha.
  Sin `backLocation` no envuelve nada: secuestrar el gesto para replicar lo que
  el sistema ya hace sería peor.

**Ojo con `context.canPop()`:** es de go_router y revienta si no hay router en
el árbol, cosa que pasa en los tests que montan una pantalla suelta. Se
pregunta al `Navigator` (`Navigator.maybeOf(context)?.canPop()`), que además es
justo lo que mira el `AppBar` para su flecha automática.

**Entrar en una publicación desde el perfil** usa `go` + `extra`, exactamente
igual que el chat y por el mismo motivo (`push` de ruta raíz a rama del shell
aborta por claves de página duplicadas).


---

## Bloqueados: visibles en el buscador, deshacibles desde su perfil

**Migración:** `supabase/migrations/20260804000023_blocked_visible_in_search.sql`.

Hasta aquí bastaba un bloqueo en **cualquiera de los dos sentidos** para
desaparecer del buscador y del perfil. A partir de ahora los dos sentidos
**dejan de ser simétricos**, y es la idea:

- **A quien yo he bloqueado:** sale en el buscador, con la etiqueta
  "Bloqueado" y sin su ciudad. Su perfil enseña **solo el nombre** y el botón
  de desbloquear. Es mi decisión y tengo que poder deshacerla sin ir a buscar
  la lista de bloqueados en ajustes.
- **A quien me ha bloqueado a mí:** sigue invisible en el buscador, y su perfil
  no enseña nada, ni el nombre. Eso no es decisión mía y no me toca revertirlo.

Cambios concretos:

- `search_profiles` devuelve una columna nueva `is_blocked` y solo excluye los
  bloqueos en sentido contrario. **Hubo que soltar la función antes de
  recrearla** (`drop function`): `create or replace` no puede cambiar el tipo de
  retorno, y añadir una columna al `returns table` lo cambia. Va dentro de la
  transacción de la migración, así que no queda hueco sin función.
- `get_public_profile` devuelve `display_name` también con bloqueo propio.
  El resto de campos siguen a null: sin el nombre, la pantalla de desbloqueo no
  podría decir a quién estás desbloqueando.
- El menú de tres puntos con bloqueo propio ofrece **Desbloquear** y
  **Reportar** (a secas, no "Reportar y bloquear": el bloqueo ya existe y la
  etiqueta no debe prometer un cambio que no ocurre). El aviso posterior dice
  "Usuario reportado.", sin mencionar un bloqueo que no ha cambiado.

> **Al escribir tests de widget del buscador:** el debounce es un
> `Future.delayed` y con el reloj falso del tester solo avanza haciendo `pump`.
> Hacer `await` de `updateQuery()` antes de pumpear cuelga el test para
> siempre. Hay que lanzarlo sin esperar y avanzar el reloj con
> `tester.pump(Duration(...))`.
