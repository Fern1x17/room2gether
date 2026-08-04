-- Buscador de usuarios (CU-20, RF-19)
--
-- El buscador encuentra perfiles por `display_name` con coincidencia parcial,
-- insensible a mayúsculas y a tildes. Dos piezas lo hacen posible sin escanear
-- la tabla entera y sin filtrar en el cliente:
--
-- 1. Índice GIN de trigramas sobre el nombre ya normalizado. Un B-tree no
--    sirve para `ilike '%texto%'`: no hay prefijo por el que arrancar.
-- 2. Una RPC `security definer`, porque la consulta necesita leer `blocks` en
--    LOS DOS SENTIDOS y `blocks_select_own` solo deja ver los bloqueos
--    propios. Desde el cliente es imposible saber quién te ha bloqueado a ti.

create schema if not exists extensions;

set search_path = public, extensions;

create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- ---------------------------------------------------------------------------
-- unaccent indexable
-- ---------------------------------------------------------------------------
-- `unaccent()` se declara STABLE (depende del diccionario que resuelva el
-- search_path), y Postgres solo indexa expresiones IMMUTABLE. Este envoltorio
-- fija el diccionario y declara la inmutabilidad, que es lo que permite crear
-- el índice de abajo. Sin él, la búsqueda sin tildes obligaría a recalcular
-- `unaccent` fila a fila en cada consulta.
create or replace function public.immutable_unaccent(p_text text)
returns text
language sql
immutable
strict
parallel safe
set search_path = extensions, public
as $$
  select unaccent('unaccent', p_text)
$$;

-- El índice va sobre la MISMA expresión que usa la consulta; si no coincidiera
-- exactamente, el planificador no lo usaría.
create index if not exists profiles_display_name_trgm_idx
  on public.profiles
  using gin (public.immutable_unaccent(display_name) gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- Búsqueda de perfiles
-- ---------------------------------------------------------------------------
-- `security definer` para poder comprobar los bloqueos en ambos sentidos. No
-- amplía lo visible: `profiles_select_authenticated` ya permite leer cualquier
-- perfil a quien tenga sesión, y esta función devuelve MENOS filas (excluye
-- bloqueados y al propio usuario) y MENOS columnas que un SELECT directo.
--
-- El texto de búsqueda se escapa antes de entrar en el LIKE: sin ello, un
-- usuario que escribiera `%` haría coincidir a todo el mundo.
create or replace function public.search_profiles(
  p_query  text,
  p_limit  integer default 20,
  p_offset integer default 0
)
returns table (
  id           uuid,
  display_name text,
  avatar_url   text,
  city_name    text
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with q as (
    select
      -- Longitud sobre el texto crudo: el escapado añade caracteres y
      -- falsearía el mínimo de 2.
      length(btrim(coalesce(p_query, ''))) as needle_length,
      public.immutable_unaccent(
        replace(
          replace(
            replace(btrim(coalesce(p_query, '')), '\', '\\'),
            '%', '\%'
          ),
          '_', '\_'
        )
      ) as needle
  )
  select p.id, p.display_name, p.avatar_url, c.name
    from public.profiles p
    cross join q
    left join public.cities c on c.id = p.city_id
   where auth.uid() is not null                  -- sin sesión no se busca
     and q.needle_length >= 2                    -- mismo suelo que el cliente
     and p.id <> auth.uid()                      -- no me encuentro a mí mismo
     and public.immutable_unaccent(p.display_name) ilike '%' || q.needle || '%'
     and not exists (
       select 1
         from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
           or (b.blocker_id = p.id       and b.blocked_id = auth.uid())
     )
   -- Los que empiezan por lo escrito, primero; luego los nombres más cortos
   -- (coincidencia proporcionalmente mayor). El id desempata para que la
   -- paginación por offset sea estable entre páginas.
   order by
     (public.immutable_unaccent(p.display_name) ilike q.needle || '%') desc,
     length(p.display_name) asc,
     p.display_name asc,
     p.id asc
   limit  least(greatest(coalesce(p_limit, 20), 1), 50)
   offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.search_profiles(text, integer, integer) from public;
grant execute on function public.search_profiles(text, integer, integer) to authenticated;
