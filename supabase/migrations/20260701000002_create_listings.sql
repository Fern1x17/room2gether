-- listings: publicaciones de busco/ofrezco habitación

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('seeking', 'offering')),
  title text not null,
  description text,
  city text not null,
  neighborhood text,
  price int not null check (price >= 0),
  photos text[] not null default '{}',
  is_featured boolean not null default false,
  featured_until timestamptz,
  is_business boolean not null default false,
  status text not null default 'active' check (status in ('active', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index listings_owner_id_idx on public.listings (owner_id);
create index listings_city_status_idx on public.listings (city, status);

create trigger set_listings_updated_at
  before update on public.listings
  for each row
  execute function public.set_updated_at();

-- RLS: el dueño edita/borra las suyas; lectura pública de las activas
alter table public.listings enable row level security;

create policy "listings_select_active_or_own"
  on public.listings for select
  to authenticated
  using (status = 'active' or owner_id = auth.uid());

create policy "listings_insert_own"
  on public.listings for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy "listings_update_own"
  on public.listings for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "listings_delete_own"
  on public.listings for delete
  to authenticated
  using (owner_id = auth.uid());
