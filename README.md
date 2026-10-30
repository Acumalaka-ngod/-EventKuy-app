# EventKuy

Aplikasi mobile event ticketing — temukan, ikuti, dan hadiri event favoritmu.
Dibangun dengan Flutter + Provider dan backend **Supabase** (Auth, PostgreSQL,
Row Level Security, dan RPC). Pembayaran Midtrans masih disimulasikan di RPC
`checkout`.

## Fitur

- Beranda: sapaan, pencarian, hero carousel, kategori, dan event terdekat per kota.
- Jelajahi: filter kategori, urutan (terpopuler/terdekat), dan pemilih kota.
- Detail event + checkout (voucher, metode pembayaran, modal sukses).
- E-tiket QR, check-in simulasi, favorit, profil, dan dashboard organizer.
- Data event, tiket, transaksi, dan favorit tersimpan di Supabase.

## Setup Supabase

1. Buat project di [supabase.com](https://supabase.com) lalu salin **Project URL**
   dan **anon/publishable key** dari Settings > API.
2. Buka **SQL Editor**, jalankan `supabase/schema.sql` lalu `supabase/seed.sql`.
3. (Disarankan untuk demo) Nonaktifkan konfirmasi email di
   Authentication > Providers > Email agar akun baru langsung dapat masuk.
4. Jalankan aplikasi dengan kunci Supabase:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Tanpa kedua define tersebut, aplikasi menampilkan layar panduan setup.

### Akun organizer

Seed event belum memiliki organizer. Setelah mendaftar, jadikan akunmu
organizer lewat SQL Editor (ganti UUID sesuai Authentication > Users):

```sql
update public.profiles set role = 'organizer' where id = '<UUID_AKUN>';
update public.events set organizer_id = '<UUID_AKUN>'
where id = '11111111-1111-4111-8111-000000000001';
```

Check-in hanya dapat dilakukan organizer pemilik event. Voucher demo:
`EVENTKUY` dan `DISKON10` (diskon Rp 25.000).

## Verifikasi

```bash
flutter analyze
flutter test
```

Widget test memakai `MockApiService`, sehingga tidak membutuhkan Supabase.

## Struktur

- `supabase/` — `schema.sql` (tabel, RLS, trigger, RPC) dan `seed.sql` (event + voucher).
- `lib/core/` — tema (`theme.dart`), breakpoint (`responsive.dart`), konfigurasi (`config.dart`), error (`errors.dart`).
- `lib/services/` — kontrak `EventKuyApi`, implementasi `SupabaseApi`, dan `MockApiService` untuk test.
- `lib/models/` — `Event`, `Ticket`, `AppUser`, `Voucher`.
- `lib/providers/` — state management dengan Provider.
- `lib/screens/` — layar per fitur (auth, home, explore, event, checkout, ticket, favorite, profile, scan, organizer, setup).
- `DESIGN_SPEC.md` — acuan desain & kebutuhan teknis.
