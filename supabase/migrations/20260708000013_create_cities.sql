-- RF-15: catálogo de ciudades para el selector con autocompletado.
-- Las ciudades se gestionan por migración o panel; el cliente NUNCA escribe.

create table public.cities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  aliases text[] not null default '{}',
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Evita ciudades duplicadas y acelera la búsqueda por nombre normalizado.
create unique index cities_normalized_name_idx on public.cities (normalized_name);

create trigger set_cities_updated_at
  before update on public.cities
  for each row
  execute function public.set_updated_at();

-- RLS: solo lectura para usuarios autenticados (coherente con el feed, que
-- exige sesión — CU-09). Se leen también las inactivas: hace falta para
-- mostrar el nombre de ciudad de perfiles/publicaciones antiguos. Sin
-- políticas de INSERT/UPDATE/DELETE: el cliente no puede escribir.
alter table public.cities enable row level security;

create policy "cities_select_authenticated"
  on public.cities for select
  to authenticated
  using (true);

-- Seed inicial: Vigo operativa; Santiago y A Coruña preparadas pero inactivas.
insert into public.cities (name, normalized_name, aliases, is_active) values
  ('Vigo', 'vigo', '{}', true),
  ('Santiago de Compostela', 'santiago de compostela', '{"santiago"}', false),
  ('A Coruña', 'a coruna', '{"la coruna","coruna"}', false);
