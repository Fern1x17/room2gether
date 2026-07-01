-- conversations: hilo de chat entre dos usuarios, opcionalmente ligado a un listing

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid references public.listings (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_distinct_users check (user_a <> user_b)
);

create index conversations_user_a_idx on public.conversations (user_a);
create index conversations_user_b_idx on public.conversations (user_b);
create index conversations_listing_id_idx on public.conversations (listing_id);

create trigger set_conversations_updated_at
  before update on public.conversations
  for each row
  execute function public.set_updated_at();

-- RLS: solo los dos participantes acceden
alter table public.conversations enable row level security;

create policy "conversations_select_participants"
  on public.conversations for select
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "conversations_insert_participant"
  on public.conversations for insert
  to authenticated
  with check (auth.uid() = user_a or auth.uid() = user_b);

create policy "conversations_update_participants"
  on public.conversations for update
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b)
  with check (auth.uid() = user_a or auth.uid() = user_b);

create policy "conversations_delete_participants"
  on public.conversations for delete
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);
