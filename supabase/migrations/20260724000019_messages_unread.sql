-- Mensajes sin leer (badge de la navegación).
--
-- La columna `messages.read_at` ya existía desde 20260701000004 pero nadie la
-- escribía nunca. No hace falta esquema nuevo: "sin leer" es
-- `read_at is null and sender_id <> auth.uid()` dentro de mis conversaciones.

-- Índice parcial: el contador solo mira las filas sin leer, que son pocas
-- frente al total de mensajes.
create index messages_unread_idx
  on public.messages (conversation_id)
  where read_at is null;

-- ---------------------------------------------------------------------------
-- Endurecimiento de la política de UPDATE
-- ---------------------------------------------------------------------------
-- `messages_update_participants` permitía a CUALQUIERA de los dos
-- participantes actualizar CUALQUIER columna de CUALQUIER mensaje del hilo,
-- incluido el `content` del otro. Existía así porque marcar `read_at` exige
-- tocar los mensajes recibidos, y RLS no distingue columnas. Hasta ahora lo
-- único que lo frenaba era el filtro `.eq('sender_id', ...)` del cliente, que
-- es una cortesía, no una garantía (ver docs/05-documentacion-tecnica.md).
--
-- Ahora se separan las dos cosas: el remitente edita lo suyo por UPDATE
-- directo, y marcar como leído pasa por una función `security definer` que
-- solo puede tocar `read_at`.
drop policy "messages_update_participants" on public.messages;

create policy "messages_update_own"
  on public.messages for update
  to authenticated
  using (sender_id = auth.uid())
  with check (sender_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Marcar una conversación como leída
-- ---------------------------------------------------------------------------
-- `security definer` para poder escribir `read_at` en mensajes ajenos, que la
-- política de arriba ya no permite. Solo toca esa columna, y solo si quien
-- llama participa en la conversación.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated integer;
begin
  if not exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and (c.user_a = auth.uid() or c.user_b = auth.uid())
  ) then
    raise exception 'No participas en esta conversación';
  end if;

  update public.messages
     set read_at = now()
   where conversation_id = p_conversation_id
     and sender_id <> auth.uid()
     and read_at is null;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Contador de no leídos por conversación
-- ---------------------------------------------------------------------------
-- `security invoker`: RLS sigue aplicando, así que solo cuenta mensajes de
-- conversaciones en las que participo.
--
-- Excluye a los usuarios bloqueados: si has bloqueado a alguien, sus mensajes
-- no deben hacerte sonar el badge. Es coherente con el resto de efectos del
-- bloqueo (CU-11) y no cambia la decisión de aplicarlo en la app: esto es una
-- consulta nuestra, no una política de RLS.
create or replace function public.unread_counts()
returns table (conversation_id uuid, unread integer)
language sql
stable
security invoker
set search_path = public
as $$
  select m.conversation_id, count(*)::integer
    from public.messages m
   where m.read_at is null
     and m.sender_id <> auth.uid()
     and not exists (
       select 1 from public.blocks b
        where b.blocker_id = auth.uid()
          and b.blocked_id = m.sender_id
     )
   group by m.conversation_id;
$$;

revoke all on function public.unread_counts() from public;
grant execute on function public.unread_counts() to authenticated;
