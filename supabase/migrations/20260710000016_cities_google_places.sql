-- RF-15: el selector de ciudades pasa a usar Google Places Autocomplete.
-- `cities` deja de ser un catálogo curado y se convierte en un registro
-- poblado bajo demanda: la primera vez que alguien selecciona una localidad
-- de Google se crea su fila vía RPC. La identidad canónica de una ciudad es
-- ahora `google_place_id`; `is_active` se reinterpreta como "ciudad foco de
-- marketing" y ya NO limita el selector.

alter table public.cities add column google_place_id text;

create unique index cities_google_place_id_idx
  on public.cities (google_place_id);

-- El nombre normalizado deja de ser único: en España existen municipios
-- distintos con el mismo nombre. El índice queda solo para acelerar el casado
-- de filas antiguas (sin place_id) por nombre/alias.
drop index public.cities_normalized_name_idx;
create index cities_normalized_name_idx on public.cities (normalized_name);

-- Devuelve la fila de `cities` para una localidad de Google Places, creándola
-- si no existe. SECURITY DEFINER porque el cliente solo tiene SELECT sobre
-- `cities`; por eso valida sus parámetros de forma defensiva.
create or replace function public.get_or_create_city(
  p_place_id text,
  p_name text,
  p_normalized_name text
) returns setof public.cities
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_city public.cities;
begin
  if p_place_id is null or length(trim(p_place_id)) = 0 or length(p_place_id) > 512
     or p_name is null or length(trim(p_name)) = 0 or length(p_name) > 256
     or p_normalized_name is null or length(trim(p_normalized_name)) = 0
     or length(p_normalized_name) > 256 then
    raise exception 'get_or_create_city: parámetros inválidos';
  end if;

  -- 1. Ciudad ya registrada por place_id.
  select * into v_city
    from public.cities
   where google_place_id = p_place_id;
  if found then
    return next v_city;
    return;
  end if;

  -- 2. Fila del catálogo antiguo (sin place_id) con el mismo nombre o alias:
  --    se reclama para este place_id en vez de duplicar la ciudad.
  update public.cities
     set google_place_id = p_place_id
   where id = (
           select id
             from public.cities
            where google_place_id is null
              and (normalized_name = p_normalized_name
                   or p_normalized_name = any (aliases))
            order by created_at
            limit 1
         )
  returning * into v_city;
  if found then
    return next v_city;
    return;
  end if;

  -- 3. Ciudad nueva. El on conflict cubre la carrera entre dos clientes que
  --    seleccionan la misma ciudad a la vez.
  insert into public.cities (name, normalized_name, google_place_id, is_active)
  values (trim(p_name), p_normalized_name, p_place_id, false)
  on conflict (google_place_id)
    do update set updated_at = now()
  returning * into v_city;
  return next v_city;
end;
$$;

revoke all on function public.get_or_create_city(text, text, text) from public;
grant execute on function public.get_or_create_city(text, text, text) to authenticated;
