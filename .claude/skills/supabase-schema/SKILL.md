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
- `city` (text) — ciudad objetivo
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
- `city`, `neighborhood` (text)
- `price` (int)
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

## Reglas al modificar la BD

1. Escribe la migración SQL en `supabase/migrations/`.
2. Define la política RLS en la misma migración.
3. Actualiza este fichero con el cambio.
4. Nunca expongas la `service_role key` en el cliente Flutter; solo la `anon key`.
