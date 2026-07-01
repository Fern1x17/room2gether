-- Bucket de Storage para avatares de perfil (CU-04 Modificar perfil).
-- Público en lectura (los perfiles ya son visibles para cualquier autenticado,
-- ver profiles_select_authenticated); cada usuario solo gestiona su propia
-- carpeta {user_id}/... dentro del bucket.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- RLS ya viene activado por defecto en storage.objects (gestionado por Supabase).

create policy "avatars_select_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
