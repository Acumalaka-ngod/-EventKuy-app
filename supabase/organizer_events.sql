-- ============================================================
-- EventKuy - Izin tabel events untuk organizer
-- Jalankan di Supabase Dashboard -> SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
-- ============================================================
--
-- RLS di schema.sql sudah membatasi:
--   - select : semua user login boleh membaca event
--   - insert : hanya organizer, dan organizer_id harus auth.uid()
--   - update : hanya organizer pemilik event
--
-- GRANT di bawah ini hanya membuka kolom yang memang boleh diubah
-- organizer. Kolom sensitif seperti rating, rating_count,
-- organizer_profile_id, organizer_id, dan created_at tidak diberikan,
-- sehingga tidak bisa diubah lewat REST langsung meskipun RLS lolos.
--
-- File ini adalah versi aman; `security_hardening.sql` mengulang grant
-- yang sama sebagai langkah migrasi terakhir.

grant select on table public.events to authenticated;

grant insert (
  organizer_id,
  organizer_profile_id,
  title,
  description,
  date,
  location,
  price,
  quota,
  image_url,
  image_urls,
  category,
  tags,
  time_range
) on table public.events to authenticated;

grant update (
  title,
  description,
  date,
  location,
  price,
  quota,
  image_url,
  image_urls,
  category,
  tags,
  time_range
) on table public.events to authenticated;
