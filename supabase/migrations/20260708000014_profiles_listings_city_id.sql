-- Sustituye profiles.city y listings.city (texto libre) por city_id, FK a
-- cities. on delete restrict: una ciudad referenciada por perfiles o
-- publicaciones no puede borrarse por accidente; para retirarla del selector
-- basta con is_active = false, sin romper datos históricos.

-- unaccent: para normalizar (quitar tildes) el texto ya guardado en el backfill.
create extension if not exists unaccent;

alter table public.profiles
  add column city_id uuid references public.cities (id) on delete restrict;

alter table public.listings
  add column city_id uuid references public.cities (id) on delete restrict;

-- ── Backfill de los datos existentes ────────────────────────────────────────
-- 1. Cada valor de texto distinto que haya hoy en profiles.city o
--    listings.city se normaliza (minúsculas, sin tildes) y se busca en
--    cities por normalized_name o alias.
-- 2. Los que no existan se CREAN como ciudades inactivas (no salen en el
--    selector, pero ninguna fila pierde su ciudad).
insert into public.cities (name, normalized_name)
select distinct on (src.norm) src.city_text, src.norm
from (
  select trim(city) as city_text, unaccent(lower(trim(city))) as norm
  from (
    select city from public.profiles
    where city is not null and trim(city) <> ''
    union all
    select city from public.listings
    where city is not null and trim(city) <> ''
  ) raw
) src
where not exists (
  select 1 from public.cities c
  where c.normalized_name = src.norm or src.norm = any (c.aliases)
)
order by src.norm, src.city_text;

-- 3. Se rellena city_id a partir del texto normalizado (nombre o alias).
update public.profiles p
set city_id = c.id
from public.cities c
where p.city is not null and trim(p.city) <> ''
  and (c.normalized_name = unaccent(lower(trim(p.city)))
       or unaccent(lower(trim(p.city))) = any (c.aliases));

update public.listings l
set city_id = c.id
from public.cities c
where c.normalized_name = unaccent(lower(trim(l.city)))
   or unaccent(lower(trim(l.city))) = any (c.aliases);

-- ── Paridad con el esquema anterior ─────────────────────────────────────────
-- listings.city era NOT NULL; profiles.city era opcional.
alter table public.listings alter column city_id set not null;

-- El índice (city, status) desaparece con la columna; su sustituto:
create index listings_city_id_status_idx on public.listings (city_id, status);

alter table public.profiles drop column city;
alter table public.listings drop column city;
