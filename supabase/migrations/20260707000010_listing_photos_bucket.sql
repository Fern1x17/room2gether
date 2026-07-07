-- Bucket de Storage para fotos de publicaciones (CU-06 Crear publicación).
-- Mismo patrón que el bucket 'avatars': lectura pública (las publicaciones
-- activas son visibles para cualquier autenticado) y cada usuario solo puede
-- escribir dentro de su propia carpeta {user_id}/... .

insert into storage.buckets (id, name, public)
values ('listing-photos', 'listing-photos', true)
on conflict (id) do nothing;

create policy "listing_photos_select_public"
  on storage.objects for select
  using (bucket_id = 'listing-photos');

create policy "listing_photos_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "listing_photos_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "listing_photos_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
