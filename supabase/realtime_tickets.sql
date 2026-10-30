-- ------------------------------------------------------------
-- Aktifkan Supabase Realtime untuk tabel tickets
-- ------------------------------------------------------------
-- Dibutuhkan fitur "check-in langsung terlihat di layar attendee":
-- saat organizer memanggil RPC check_in_ticket, baris tickets milik
-- attendee berubah statusnya menjadi 'checked_in'. Dengan realtime
-- aktif, aplikasi attendee menerima perubahan itu tanpa reload.
--
-- Jalankan sekali di Supabase Studio -> SQL Editor.
-- Tanpa langkah ini aplikasi tetap jalan, tetapi pembaruan hanya
-- terjadi lewat polling 10 detik saat layar Tiket terbuka.
--
-- Catatan: RLS tetap berlaku. Policy `tickets_select_own_or_organizer`
-- membuat attendee hanya menerima baris tiketnya sendiri.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'tickets'
  ) then
    alter publication supabase_realtime add table public.tickets;
  end if;
end $$;

-- Verifikasi (harus mengembalikan satu baris public.tickets):
-- select * from pg_publication_tables
-- where pubname = 'supabase_realtime' and tablename = 'tickets';
