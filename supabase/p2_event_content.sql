-- ============================================================
-- EventKuy - Migrasi P2: Konten Event (Organizer + Rating)
-- Jalankan di Supabase Dashboard -> SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
-- ============================================================

-- ------------------------------------------------------------
-- Tabel organizer (penyelenggara acara)
-- ------------------------------------------------------------

create table if not exists public.organizers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete set null,
  name text not null default '',
  bio text not null default '',
  avatar_url text,
  city text not null default '',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Kolom baru pada events: organizer_profile_id, rating, rating_count
-- ------------------------------------------------------------

alter table public.events
  add column if not exists organizer_profile_id uuid
    references public.organizers (id) on delete set null;

alter table public.events
  add column if not exists rating numeric(2, 1) not null default 0;

alter table public.events
  add column if not exists rating_count integer not null default 0;

-- ------------------------------------------------------------
-- Row Level Security untuk organizers
-- ------------------------------------------------------------

alter table public.organizers enable row level security;

drop policy if exists "organizers_insert_service" on public.organizers;
drop policy if exists "organizers_update_service" on public.organizers;
drop policy if exists "organizers_insert_own" on public.organizers;
drop policy if exists "organizers_update_own" on public.organizers;
drop policy if exists "organizers_select_authenticated" on public.organizers;

create policy "organizers_select_authenticated" on public.organizers
  for select to authenticated
  using (true);

-- Hanya organizer yang boleh membuat profil untuk dirinya sendiri.
-- Status `verified` tidak termasuk grant insert, jadi selalu false.
create policy "organizers_insert_own" on public.organizers
  for insert to authenticated
  with check (owner_id = auth.uid() and public.is_organizer());

-- Owner hanya boleh mengubah kolom profil; `owner_id` dan `verified`
-- tidak termasuk grant update sehingga tidak bisa diubah dari client.
create policy "organizers_update_own" on public.organizers
  for update to authenticated
  using (owner_id = auth.uid() and public.is_organizer())
  with check (owner_id = auth.uid() and public.is_organizer());

revoke all on table public.organizers from anon, authenticated;
grant select on table public.organizers to authenticated;
grant insert (owner_id, name, bio, avatar_url, city)
  on table public.organizers to authenticated;
grant update (name, bio, avatar_url, city)
  on table public.organizers to authenticated;

-- ------------------------------------------------------------
-- Seed organizer demo
-- ------------------------------------------------------------

insert into public.organizers (id, owner_id, name, bio, avatar_url, city, verified)
values
  (
    'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
    null,
    'EventKuy Official',
    'Penyelenggara resmi platform EventKuy. Menyelenggarakan berbagai acara musik, workshop, seminar, dan olahraga di seluruh Indonesia.',
    null,
    'Jakarta',
    true
  ),
  (
    'b25d7744-cee0-4bf7-b123-dea60edd901b',
    null,
    'Raga Nusantara',
    'Komunitas penggemar musik lokal yang mengedepankan karya anak bangsa dari Sabang hingga Merauke.',
    null,
    'Bandung',
    true
  ),
  (
    'c36e8855-dff1-4c08-c234-efb71fee022c',
    null,
    'TechCamp Indonesia',
    'Platform edukasi teknologi dan startup dengan workshop hands-on serta seminar dari praktisi industri.',
    null,
    'Jakarta',
    false
  )
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- Update event demo dengan organizer_profile_id, rating, rating_count
-- (idempotent: update jika event sudah ada)
-- ------------------------------------------------------------

update public.events
set organizer_profile_id = 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
    rating = 4.9,
    rating_count = 320
where id = '11111111-1111-4111-8111-000000000001';

update public.events
set organizer_profile_id = 'b25d7744-cee0-4bf7-b123-dea60edd901b',
    rating = 4.7,
    rating_count = 180
where id = '11111111-1111-4111-8111-000000000002';

update public.events
set organizer_profile_id = 'c36e8855-dff1-4c08-c234-efb71fee022c',
    rating = 4.5,
    rating_count = 45
where id = '11111111-1111-4111-8111-000000000003';

update public.events
set organizer_profile_id = 'c36e8855-dff1-4c08-c234-efb71fee022c',
    rating = 4.3,
    rating_count = 90
where id = '11111111-1111-4111-8111-000000000004';

update public.events
set organizer_profile_id = 'b25d7744-cee0-4bf7-b123-dea60edd901b',
    rating = 4.8,
    rating_count = 210
where id = '11111111-1111-4111-8111-000000000005';

update public.events
set organizer_profile_id = 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
    rating = 4.6,
    rating_count = 60
where id = '11111111-1111-4111-8111-000000000006';

update public.events
set organizer_profile_id = 'c36e8855-dff1-4c08-c234-efb71fee022c',
    rating = 4.4,
    rating_count = 75
where id = '11111111-1111-4111-8111-000000000007';

-- ------------------------------------------------------------
-- Catatan: pemetaan organizer ke owner (auth.user) dilakukan manual
-- di Supabase Studio, contoh:
--
-- update public.organizers
--   set owner_id = '<UUID_AKUN_ORGANIZER>'
--   where id = 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa';
--
-- Tabel organizers dapat dibaca oleh semua user login; penulisan
-- masih dibatasi oleh kebijakan di atas (sementara untuk seed/manual).
-- ============================================================
