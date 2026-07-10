---
name: supabase-schema
description: Esquema de base de datos del proyecto en Supabase. Úsala SIEMPRE que trabajes con tablas, consultas, migraciones, Row Level Security o el cliente de Supabase en Flutter. Contiene las tablas, sus relaciones y las reglas de RLS.
---

# Esquema de datos — Supabase

> Mantén este fichero sincronizado con el estado real de la base de datos.
> Toda modificación de la BD debe hacerse mediante migración SQL, nunca a mano.

## Principios

- **Row Level Security (RLS) activado en TODAS las tablas.** Sin excepción.
- Los `id` son `uuid` con `default gen_random_uuid()`.
- Timestamps `created_at` y `updated_at` (`timestamptz default now()`) en todas las tablas.
- Las claves foráneas usan `on delete cascade` o `set null` según convenga; decídelo explícitamente.
- Nombres de tablas en plural e inglés (`profiles`, `listings`, `messages`).

## Tablas previstas (MVP)

### profiles
Extiende el `auth.users` de Supabase. Un perfil por usuario. Se crea
automáticamente al registrarse (trigger `handle_new_user` sobre `auth.users`,
que lee `birthdate` de los metadatos de `signUp()`).
- `id` (uuid, PK, = auth.users.id)
- `display_name` (text)
- `birthdate` (date, NOT NULL) — fecha de nacimiento; check de mayoría de edad
  (`birthdate <= current_date - 18 años`, constraint `profiles_adult_check`)
- `role` (text: 'user' / 'moderator', default 'user') — el "tipo" del modelo de
  datos; no editable desde el cliente, se promociona con service_role
- `bio` (text)
- `avatar_url` (text)
- `city_id` (uuid, FK → cities.id, on delete restrict, nullable) — ciudad objetivo
- `budget_min`, `budget_max` (int) — presupuesto mensual
- Preferencias de convivencia: `is_smoker` (bool), `has_pets` (bool),
  `cleanliness_level` (int 1–5), `schedule` (text: madrugador/noctámbulo), etc.
- `is_verified` (bool)
- RLS: cada usuario solo edita SU perfil; lectura pública de campos no sensibles.

### listings (publicaciones)
- `id` (uuid, PK)
- `owner_id` (uuid, FK → profiles.id)
- `type` (enum: 'seeking' busco / 'offering' ofrezco)
- `title`, `description` (text)
- `city_id` (uuid, FK → cities.id, on delete restrict, NOT NULL), `neighborhood` (text)
- `price` (int, nullable — solo 'offering'), `budget_min`/`budget_max` (int,
  nullable — solo 'seeking'; check de coherencia por tipo)
- `photos` (text[] o tabla aparte listing_photos)
- `is_featured` (bool) — para los destacados de pago
- `featured_until` (timestamptz, nullable)
- `is_business` (bool) — true si es de una inmobiliaria (Fase 3)
- `status` (enum: 'active' / 'closed')
- RLS: el dueño edita/borra las suyas; lectura pública de las activas.

### conversations
- `id` (uuid, PK)
- `user_a`, `user_b` (uuid, FK → profiles.id)
- `listing_id` (uuid, FK → listings.id, nullable)
- RLS: solo los dos participantes acceden.

### messages
- `id` (uuid, PK)
- `conversation_id` (uuid, FK → conversations.id)
- `sender_id` (uuid, FK → profiles.id)
- `content` (text)
- `read_at` (timestamptz, nullable)
- RLS: solo participantes de la conversación.
- Realtime: suscripción a INSERT para el chat en vivo.

### reports (moderación)
- `id` (uuid, PK)
- `reporter_id` (uuid, FK → profiles.id)
- `reported_user_id` (uuid, FK → profiles.id, nullable)
- `reported_listing_id` (uuid, FK → listings.id, nullable)
- `reason` (text)
- `status` (enum: 'pending' / 'reviewed' / 'actioned')

### blocks (bloqueo entre usuarios)
- `blocker_id`, `blocked_id` (uuid, FK → profiles.id)
- PK compuesta.

### listing_addresses (dirección exacta de una publicación, CU-06)
- `listing_id` (uuid, PK y FK → listings.id, on delete cascade) — 1:1
- `formatted_address` (text, NOT NULL) — dirección formateada de Google Places
- `google_place_id` (text)
- `latitude`, `longitude` (double precision)
- `is_public` (bool, default false) — true = el dueño eligió mostrar la
  dirección completa en el anuncio
- Vive en tabla propia (no como columnas de `listings`) porque RLS es por
  fila: "mostrar solo el barrio" se garantiza así en la BD.
- RLS: SELECT solo si `is_public` o si la publicación es del usuario;
  INSERT/UPDATE/DELETE solo el dueño de la publicación.
- El barrio y la dirección vienen de Google Places (el catálogo
  `neighborhoods` se retiró en la migración `20260710000017`). OJO:
  `listings.neighborhood` sigue siendo texto y guarda el nombre de barrio
  que devuelve Places; es lo que se muestra si no hay dirección pública.

### cities (registro de ciudades, RF-15 — poblado desde Google Places)
- `id` (uuid, PK)
- `name` (text) — nombre canónico a mostrar, ej. "A Coruña"
- `normalized_name` (text, indexado NO único: hay municipios homónimos en
  España) — minúsculas y sin tildes, ej. "a coruna"; solo sirve para casar
  filas antiguas sin place_id
- `aliases` (text[]) — nombres alternativos normalizados, ej. {"la coruna"}
- `google_place_id` (text, único) — identidad canónica de la ciudad (Google
  Places); evita duplicados de la misma localidad
- `is_active` (bool, default false) — "ciudad foco de marketing"; NO limita
  el selector (cualquier localidad de España es seleccionable)
- RLS: SELECT para authenticated; NINGUNA escritura directa desde el cliente.
- RPC `get_or_create_city(p_place_id, p_name, p_normalized_name)` — security
  definer, execute solo para authenticated. Devuelve la fila por place_id;
  si no existe, reclama una fila sin place_id que case por nombre/alias; si
  tampoco, la inserta (`on conflict (google_place_id)` para carreras). Es la
  única vía de escritura en `cities` desde la app; las FKs siguen con
  `on delete restrict`.

## Reglas al modificar la BD

1. Escribe la migración SQL en `supabase/migrations/`.
2. Define la política RLS en la misma migración.
3. Actualiza este fichero con el cambio.
4. Nunca expongas la `service_role key` en el cliente Flutter; solo la `anon key`.
