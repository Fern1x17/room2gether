-- blocks: bloqueo entre usuarios en el chat

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self_block check (blocker_id <> blocked_id)
);

create index blocks_blocked_id_idx on public.blocks (blocked_id);

create trigger set_blocks_updated_at
  before update on public.blocks
  for each row
  execute function public.set_updated_at();

-- RLS: cada usuario solo ve y gestiona sus propios bloqueos
alter table public.blocks enable row level security;

create policy "blocks_select_own"
  on public.blocks for select
  to authenticated
  using (blocker_id = auth.uid());

create policy "blocks_insert_own"
  on public.blocks for insert
  to authenticated
  with check (blocker_id = auth.uid());

create policy "blocks_delete_own"
  on public.blocks for delete
  to authenticated
  using (blocker_id = auth.uid());
