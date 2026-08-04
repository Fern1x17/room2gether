-- Los bloqueados por mí vuelven al buscador, marcados (CU-20 / CU-19)
--
-- Cambia QUIÉN se esconde. Hasta ahora bastaba un bloqueo en cualquiera de los
-- dos sentidos para desaparecer. A partir de aquí los dos sentidos dejan de ser
-- simétricos, y es a propósito:
--
--   * A quien YO he bloqueado: sale en el buscador, marcado como bloqueado, y
--     su perfil enseña solo el nombre y el botón de desbloquear. Es MI decisión
--     y tengo que poder deshacerla; esconderlo del todo obligaba a ir a buscar
--     la lista de bloqueados en ajustes.
--   * A quien me ha bloqueado A MÍ: sigue invisible, igual que antes. Eso no es
--     decisión mía y no me toca revertirlo.
--
-- El resto de datos (bio, ciudad, presupuesto, preferencias) siguen ocultos con
-- bloqueo en cualquiera de los dos sentidos.

-- ---------------------------------------------------------------------------
-- Buscador
-- ---------------------------------------------------------------------------
-- Se suelta antes de recrearla: `create or replace` no puede cambiar el tipo
-- de retorno, y aquí se añade la columna `is_blocked`. Va dentro de la
-- transacción de la migración, así que en ningún momento queda un hueco sin
-- función.
drop function if exists public.search_profiles(text, integer, integer);

create function public.search_profiles(
  p_query  text,
  p_limit  integer default 20,
  p_offset integer default 0
)
returns table (
  id           uuid,
  display_name text,
  avatar_url   text,
  city_name    text,
  is_blocked   boolean
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
      ) as needle,
      -- Sin escapar: la similitud no interpreta comodines, y meterle barras
      -- invertidas falsearía el parecido.
      public.immutable_unaccent(btrim(coalesce(p_query, ''))) as raw_needle
  )
  select
    p.id,
    p.display_name,
    p.avatar_url,
    c.name,
    exists (
      select 1
        from public.blocks b
       where b.blocker_id = auth.uid() and b.blocked_id = p.id
    ) as is_blocked
    from public.profiles p
    cross join q
    left join public.cities c on c.id = p.city_id
   where auth.uid() is not null                  -- sin sesión no se busca
     and q.needle_length >= 2                    -- mismo suelo que el cliente
     and p.id <> auth.uid()                      -- no me encuentro a mí mismo
     and (
       -- 1. Contiene lo escrito, tal cual. Esta rama sí usa el índice.
       public.immutable_unaccent(p.display_name) ilike '%' || q.needle || '%'
       -- 2. O se le parece lo bastante.
       or word_similarity(
            q.raw_needle, public.immutable_unaccent(p.display_name)
          ) >= 0.4
     )
     -- Solo se excluye a quien me ha bloqueado A MÍ. Los que he bloqueado yo
     -- salen, con su bandera puesta.
     and not exists (
       select 1
         from public.blocks b
        where b.blocker_id = p.id and b.blocked_id = auth.uid()
     )
   -- Primero lo literal (empieza por lo escrito, luego lo contiene) y después
   -- lo parecido, de más a menos. El id desempata para que la paginación por
   -- offset sea estable entre páginas.
   order by
     case
       when public.immutable_unaccent(p.display_name)
              ilike q.needle || '%'             then 0
       when public.immutable_unaccent(p.display_name)
              ilike '%' || q.needle || '%'      then 1
       else                                          2
     end asc,
     word_similarity(
       q.raw_needle, public.immutable_unaccent(p.display_name)
     ) desc,
     length(p.display_name) asc,
     p.display_name asc,
     p.id asc
   limit  least(greatest(coalesce(p_limit, 20), 1), 50)
   offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.search_profiles(text, integer, integer) from public;
grant execute on function public.search_profiles(text, integer, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- Perfil público
-- ---------------------------------------------------------------------------
-- Con bloqueo propio se devuelve el nombre —y nada más— para poder decir a
-- quién estás desbloqueando. Si el bloqueo es del otro, sigue sin salir nada.
create or replace function public.get_public_profile(p_user_id uuid)
returns table (
  id                uuid,
  display_name      text,
  avatar_url        text,
  bio               text,
  city_name         text,
  budget_min        integer,
  budget_max        integer,
  is_smoker         boolean,
  has_pets          boolean,
  cleanliness_level integer,
  schedule          text,
  is_visible        boolean,
  is_blocked_by_me  boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with rel as (
    select
      auth.uid() as viewer,
      exists (
        select 1
          from public.blocks b
         where b.blocker_id = auth.uid() and b.blocked_id = p_user_id
      ) as blocked_by_me,
      exists (
        select 1
          from public.blocks b
         where b.blocker_id = p_user_id and b.blocked_id = auth.uid()
      ) as blocks_me
  ),
  v as (
    select
      rel.viewer,
      rel.blocked_by_me,
      -- Basta un bloqueo en cualquiera de los dos sentidos para ocultar todo.
      not (rel.blocked_by_me or rel.blocks_me) as visible
    from rel
  )
  select
    p.id,
    -- El nombre sale también con bloqueo propio: sin él, la pantalla de
    -- desbloqueo no podría decir a quién vas a desbloquear.
    case when v.visible or v.blocked_by_me then p.display_name end,
    case when v.visible then p.avatar_url        end,
    case when v.visible then p.bio               end,
    case when v.visible then c.name              end,
    case when v.visible then p.budget_min        end,
    case when v.visible then p.budget_max        end,
    case when v.visible then p.is_smoker         end,
    case when v.visible then p.has_pets          end,
    case when v.visible then p.cleanliness_level end,
    case when v.visible then p.schedule          end,
    v.visible,
    v.blocked_by_me
    from public.profiles p
   cross join v
    left join public.cities c on c.id = p.city_id
   where v.viewer is not null          -- sin sesión no se ve ningún perfil
     and p.id = p_user_id;
$$;

revoke all on function public.get_public_profile(uuid) from public;
grant execute on function public.get_public_profile(uuid) to authenticated;
