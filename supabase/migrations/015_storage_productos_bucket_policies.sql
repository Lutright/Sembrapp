-- Bucket y políticas para imágenes de productos.
-- Corrige fallos de upload (insert/update en storage.objects) para usuarios autenticados.

insert into storage.buckets (id, name, public)
values ('productos', 'productos', true)
on conflict (id) do nothing;

drop policy if exists "Public can read productos images" on storage.objects;
create policy "Public can read productos images"
  on storage.objects for select
  using (bucket_id = 'productos');

drop policy if exists "Authenticated can upload own productos images" on storage.objects;
create policy "Authenticated can upload own productos images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'productos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Authenticated can update own productos images" on storage.objects;
create policy "Authenticated can update own productos images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'productos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'productos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Authenticated can delete own productos images" on storage.objects;
create policy "Authenticated can delete own productos images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'productos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
