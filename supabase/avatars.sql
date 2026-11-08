-- ============================================================
-- EventKuy - Supabase Storage untuk foto profil
-- Jalankan sekali di SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
-- ============================================================

-- 1. Bucket publik untuk avatar. Nama file diawali id user.
--    Batas MIME/ukuran juga ditegakkan di server, bukan hanya di client.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- 2. Semua orang boleh melihat avatar (bucket publik).
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

-- 3. User hanya boleh menulis di foldernya sendiri: <user_id>/...
drop policy if exists "avatars_owner_insert" on storage.objects;
create policy "avatars_owner_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_owner_update" on storage.objects;
create policy "avatars_owner_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_owner_delete" on storage.objects;
create policy "avatars_owner_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Verifikasi cepat:
-- select id, name, public, file_size_limit, allowed_mime_types
-- from storage.buckets where id = 'avatars';
-- select name from storage.objects where bucket_id = 'avatars' limit 10;
