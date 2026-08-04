-- Ver perfil de otro usuario (CU-19, RF-20)
--
-- Devuelve los datos públicos de un perfil: exactamente los campos que su
-- dueño puede cambiar en la pestaña Perfil. Quedan fuera `birthdate` (dato
-- personal que nadie edita y que no hace falta enseñar), `role` e
-- `is_verified`, que gestiona el servidor.
--
-- Es `security definer` por el bloqueo: `blocks_select_own` solo deja ver los
-- bloqueos propios, así que desde el cliente es imposible saber si el perfil
-- que estás abriendo te ha bloqueado a ti. Y como
-- `profiles_select_authenticated` permite leer cualquier perfil, esconder los
-- datos en la app no serviría de nada: la fila viajaría igualmente. La
-- decisión de qué se ve tiene que tomarse aquí.

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
  -- Con bloqueo se devuelve la fila igualmente, pero con los datos a null: la
  -- pantalla necesita saber que el usuario existe y si el bloqueo es suyo
  -- (para ofrecer desbloquear), sin recibir ni un campo del perfil.
  select
    p.id,
    case when v.visible then p.display_name      end,
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
