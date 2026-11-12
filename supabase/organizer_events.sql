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
-- File ini hanya menambahkan GRANT tabel supaya PostgREST mengizinkan
-- operasi tersebut. Tanpa GRANT, request dari aplikasi bisa ditolak
-- dengan "permission denied for table events" meskipun policy RLS lolos.

grant select, insert, update on table public.events to authenticated;
