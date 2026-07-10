-- CU-06: dirección exacta opcional de una publicación, con privacidad.
-- La dirección vive en su propia tabla (no como columnas de `listings`)
-- porque RLS es por fila: así "mostrar solo el barrio" se garantiza en la
-- base de datos y no depende del cliente.

create table public.listing_addresses (
  listing_id uuid primary key
    references public.listings (id) on delete cascade,
  formatted_address text not null,
  google_place_id text,
  latitude double precision,
  longitude double precision,
  -- true = el dueño eligió mostrar la dirección completa en el anuncio.
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_listing_addresses_updated_at
  before update on public.listing_addresses
  for each row
  execute function public.set_updated_at();

alter table public.listing_addresses enable row level security;

-- Lectura: la dirección completa solo es visible si es pública o si la
-- publicación es tuya.
create policy "listing_addresses_select"
  on public.listing_addresses for select
  to authenticated
  using (
    is_public
    or exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );

-- Escritura: solo el dueño de la publicación.
create policy "listing_addresses_insert"
  on public.listing_addresses for insert
  to authenticated
  with check (
    exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );

create policy "listing_addresses_update"
  on public.listing_addresses for update
  to authenticated
  using (
    exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );

create policy "listing_addresses_delete"
  on public.listing_addresses for delete
  to authenticated
  using (
    exists (
      select 1 from public.listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );

-- El barrio pasa a venir de Google Places (RF-15): el catálogo curado de
-- barrios deja de usarse y se retira. `listings.neighborhood` sigue siendo
-- texto y ahora guarda el nombre de barrio que devuelve Places.
drop table public.neighborhoods;
