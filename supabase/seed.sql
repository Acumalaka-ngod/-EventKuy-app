-- ============================================================
-- EventKuy - Seed data
-- Jalankan setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
-- ============================================================

-- Jaga-jaga: database yang dibuat dari schema.sql versi lama belum punya
-- kolom galeri. Migrasi ini idempotent sehingga seed tetap bisa dijalankan
-- sendiri tanpa error "column image_urls does not exist".
alter table if exists public.events
  add column if not exists image_urls text[] not null default '{}';

-- Voucher demo
-- Aturan bisnis: satu kode voucher hanya bisa dipakai sekali secara global
-- (lihat security_hardening.sql). Karena itu kuota selalu 1.
insert into public.vouchers (code, discount, active_from, active_to, quota)
values
  ('EVENTKUY', 25000, now() - interval '1 day', now() + interval '1 year', 1),
  ('DISKON10', 25000, now() - interval '1 day', now() + interval '1 year', 1)
on conflict (code) do update
set discount = excluded.discount,
    active_from = excluded.active_from,
    active_to = excluded.active_to,
    quota = excluded.quota;

-- Event demo (sama dengan data mock aplikasi)
insert into public.events
  (id, title, description, date, location, price, quota, image_url, image_urls, category, tags, time_range)
values
  (
    '11111111-1111-4111-8111-000000000001',
    'Sound of Tomorrow',
    'Sound of Tomorrow adalah festival musik yang menghadirkan deretan musisi terbaik dari berbagai genre. Nikmati pengalaman tak terlupakan bersama teman-teman, dengan panggung megah dan fasilitas lengkap.',
    '2025-07-12',
    'Istora Senayan, Jl. Pintu Satu Senayan No. 1, Jakarta Pusat',
    750000, 3000,
    'assets/images/event_sound.jpg',
    array['assets/images/event_wtf.jpg', 'assets/images/event_photo.jpg'],
    'Konser',
    array['Musik', 'Festival', 'Food & Beverage'],
    '15:00 - 23:00'
  ),
  (
    '11111111-1111-4111-8111-000000000002',
    'We The Fest 2025',
    'Festival musik tahunan terbesar di Jakarta.',
    '2025-07-25',
    'Gelora Bung Karno (GBK), Jl. Pintu Satu Senayan, Jakarta Pusat',
    750000, 10000,
    'assets/images/event_wtf.jpg',
    array['assets/images/event_sound.jpg', 'assets/images/event_marketing.jpg'],
    'Konser',
    array['Musik', 'Festival'],
    '14:00 - 23:00'
  ),
  (
    '11111111-1111-4111-8111-000000000003',
    'Photography Workshop',
    'Workshop fotografi untuk pemula sampai pro.',
    '2025-07-12',
    'Braga Creative Hub, Jl. Braga No. 21, Bandung',
    250000, 200,
    'assets/images/event_photo.jpg',
    array['assets/images/event_uiux.jpg', 'assets/images/event_sound.jpg'],
    'Workshop',
    array['Fotografi'],
    '09:00 - 15:00'
  ),
  (
    '11111111-1111-4111-8111-000000000004',
    'Future of Technology',
    'Seminar AI, startup, dan masa depan teknologi.',
    '2025-07-18',
    'Jakarta Convention Center, Jl. Gatot Subroto, Jakarta Pusat',
    150000, 1000,
    'assets/images/event_tech.jpg',
    array['assets/images/event_marketing.jpg', 'assets/images/event_uiux.jpg'],
    'Seminar',
    array['Teknologi'],
    '09:00 - 17:00'
  ),
  (
    '11111111-1111-4111-8111-000000000005',
    'Jakarta Running Festival',
    'Lari bersama 5K & 10K di Monas.',
    '2025-07-27',
    'Kawasan Monas, Jl. Silang Monas, Jakarta Pusat',
    300000, 5000,
    'assets/images/event_run.jpg',
    array['assets/images/event_sound.jpg', 'assets/images/event_wtf.jpg'],
    'Olahraga',
    array['Lari', 'Komunitas'],
    '05:00 - 10:00'
  ),
  (
    '11111111-1111-4111-8111-000000000006',
    'UI/UX Design Workshop',
    'Belajar desain produk dari praktisi.',
    '2025-07-05',
    'GoWork Chubb Square, Jl. M.H. Thamrin No. 10, Jakarta Pusat',
    200000, 300,
    'assets/images/event_uiux.jpg',
    array['assets/images/event_photo.jpg', 'assets/images/event_tech.jpg'],
    'Workshop',
    array['Desain'],
    '10:00 - 16:00'
  ),
  (
    '11111111-1111-4111-8111-000000000007',
    'Digital Marketing Summit',
    'Strategi growth & ads terbaru.',
    '2025-07-08',
    'Gedung Merdeka, Jl. Asia Afrika No. 65, Bandung',
    350000, 500,
    'assets/images/event_marketing.jpg',
    array['assets/images/event_tech.jpg', 'assets/images/event_wtf.jpg'],
    'Seminar',
    array['Bisnis'],
    '09:00 - 17:00'
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    date = excluded.date,
    location = excluded.location,
    price = excluded.price,
    quota = excluded.quota,
    image_url = excluded.image_url,
    image_urls = excluded.image_urls,
    category = excluded.category,
    tags = excluded.tags,
    time_range = excluded.time_range;

-- ============================================================
-- Menjadikan sebuah akun sebagai organizer (jalankan manual).
-- Ganti <UUID_AKUN> dengan id dari tabel Authentication > Users,
-- lalu tetapkan event yang dikelola:
--
-- update public.profiles
--   set role = 'organizer'
--   where id = '<UUID_AKUN>';
--
-- update public.events
--   set organizer_id = '<UUID_AKUN>'
--   where id = '11111111-1111-4111-8111-000000000001';
-- ============================================================
