-- reports: moderación, reporte de usuarios o publicaciones

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_user_id uuid references public.profiles (id) on delete cascade,
  reported_listing_id uuid references public.listings (id) on delete cascade,
  reason text not null,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'actioned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_target_check
    check (reported_user_id is not null or reported_listing_id is not null)
);

create index reports_reporter_id_idx on public.reports (reporter_id);

create trigger set_reports_updated_at
  before update on public.reports
  for each row
  execute function public.set_updated_at();

-- RLS: el usuario crea reportes y ve solo los suyos; revisión y cambio de status
-- se hace con la service_role (el panel de moderación no usa la anon key)
alter table public.reports enable row level security;

create policy "reports_select_own"
  on public.reports for select
  to authenticated
  using (reporter_id = auth.uid());

create policy "reports_insert_own"
  on public.reports for insert
  to authenticated
  with check (reporter_id = auth.uid());
