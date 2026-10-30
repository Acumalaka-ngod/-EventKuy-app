-- ============================================================
-- EventKuy - Supabase Storage untuk gambar event
-- Jalankan sekali di SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
-- ============================================================

-- 1. Bucket publik untuk gambar/poster event.
insert into storage.buckets (id, name, public)
values ('event-images', 'event-images', true)
on conflict (id) do update set public = excluded.public;

-- 2. Semua orang boleh melihat gambar (bucket publik).
drop policy if exists "event_images_public_read" on storage.objects;
create policy "event_images_public_read"
on storage.objects for select
using (bucket_id = 'event-images');

-- 3. Hanya organizer yang boleh upload / ganti / hapus gambar.
drop policy if exists "event_images_organizer_insert" on storage.objects;
create policy "event_images_organizer_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'event-images'
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'organizer'
  )
);

drop policy if exists "event_images_organizer_update" on storage.objects;
create policy "event_images_organizer_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'event-images'
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'organizer'
  )
);

drop policy if exists "event_images_organizer_delete" on storage.objects;
create policy "event_images_organizer_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'event-images'
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'organizer'
  )
);

-- 4. Contoh mengisi image_url event dengan file yang sudah diupload:
-- update public.events
-- set image_url = 'https://<project-ref>.supabase.co/storage/v1/object/public/event-images/nama-file.jpg'
-- where id = '11111111-1111-4111-8111-000000000001';
