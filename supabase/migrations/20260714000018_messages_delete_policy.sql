-- Extensión CU-10 (editar/borrar mensajes): política RLS de borrado.
-- Solo el remitente original puede borrar su mensaje.
--
-- Contexto: la política se añadió también a 20260701000004_create_messages.sql
-- (para que un `db reset` desde cero la incluya), pero esa migración ya estaba
-- aplicada en el proyecto remoto ANTES del cambio, así que editarla no tuvo
-- efecto allí. Esta migración la aplica de verdad.
-- `drop policy if exists` la hace idempotente: no falla si ya existe (por el
-- reset local o por haberla creado a mano desde el SQL Editor).

drop policy if exists "messages_delete_sender" on public.messages;

create policy "messages_delete_sender"
  on public.messages for delete
  to authenticated
  using ( sender_id = auth.uid() );
