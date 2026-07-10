create TABLE public.neighborhoods (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references public.cities (id) on delete restrict,
  name text not null,
  normalized_name text not null,
  aliases text[] not null default '{}',
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Evita barrios duplicados y acelera la búsqueda por nombre normalizado.
create unique index neighborhoods_normalized_name_idx on public.neighborhoods (normalized_name);

create trigger set_neighborhoods_updated_at
  before update on public.neighborhoods
  for each row
  execute function public.set_updated_at();

-- RLS: solo lectura para usuarios autenticados (coherente con el feed, que
-- exige sesión — CU-09). Se leen también las inactivas: hace falta para
-- mostrar el nombre de ciudad de perfiles/publicaciones antiguos. Sin
-- políticas de INSERT/UPDATE/DELETE: el cliente no puede escribir.
alter table public.neighborhoods enable row level security;

create policy "neighborhoods_select_authenticated"
  on public.neighborhoods for select
  to authenticated
  using (true);

-- Seed inicial: barrios de Coruña operativos
insert into public.neighborhoods (city_id, name, normalized_name, aliases, is_active) VALUES
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'A Zapateira', 'a zapateira', '{"zapateira"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'A Grela', 'a grela', '{"grela"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'O Ventorrillo', 'o ventorrillo', '{"ventorrillo"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'O Castrillón', 'o castrillon', '{"castrillon"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'O Burgo', 'o burgo', '{"burgo", "el burgo"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'O Birloque', 'o birloque', '{"birloque", "el birloque"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'O Mesoiro', 'o mesoiro', '{"mesoiro", "el mesoiro", "novo mesoiro", "nuevo mesoiro"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, '4 Caminos', '4 caminos', '{"catro caminos", "cuatro caminos", "catro camiños", "4 camiños"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Paxariñas', 'paxarinas', '{pajaritas}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Elviña', 'elvina', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Os mallos', 'os mallos', '{"mallos", "os mayos", "mayos"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Riazor', 'riazor', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Orzán', 'orzan', '{"o orzan"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Os Castros', 'os castros', '{"castros"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Adurmideiras', 'adurmideiras', '{"adormideras", "dormideras", "durmideiras"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Oza', 'oza', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Meicende', 'meicende', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Plaza de Pontevedra', 'plaza de pontevedra', '{"pza de pontevedra", "praza de pontevedra", "plaza pontevedra", "pza pontevedra"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Plaza de Ourense', 'plaza de ourense', '{"pza de ourense", "praza de ourense", "plaza ourense", "pza ourense"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Montealto', 'montealto', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Avenida de Finisterre', 'avenida de finisterre', '{"avd de finisterre"}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Oleiros', 'oleiros', '{}', true),
  ('0f473e28-c801-464b-82e6-b00a38ef255c'::uuid, 'Estación de autobuses', 'estacion de autobuses', '{"estacion"}', true);