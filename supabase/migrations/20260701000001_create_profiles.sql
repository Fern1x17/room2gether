-- profiles: extiende auth.users, un perfil por usuario

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  age int not null check (age >= 18),
  bio text,
  avatar_url text,
  city text,
  budget_min int,
  budget_max int,
  is_smoker boolean not null default false,
  has_pets boolean not null default false,
  cleanliness_level int check (cleanliness_level between 1 and 5),
  schedule text check (schedule in ('early_riser', 'night_owl')),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_budget_range_check
    check (budget_min is null or budget_max is null or budget_min <= budget_max)
);

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- RLS: cada usuario solo edita su propio perfil; lectura para usuarios autenticados
alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_delete_own"
  on public.profiles for delete
  to authenticated
  using (auth.uid() = id);
