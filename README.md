# EventKuy

Aplikasi mobile event ticketing — temukan, ikuti, dan hadiri event favoritmu.
Dibangun dengan Flutter + Provider dan backend **Supabase** (Auth, PostgreSQL,
Row Level Security, dan RPC). Pembayaran Midtrans masih disimulasikan di RPC
`checkout`.

## Fitur

- Beranda: sapaan, pencarian, hero carousel, kategori, dan event terdekat per kota.
- Jelajahi: filter kategori, urutan (terpopuler/terdekat), dan pemilih kota.
- Detail event + checkout (voucher, metode pembayaran, modal sukses).
- E-tiket QR dengan unduh PDF, check-in lewat kamera (input kode manual sebagai fallback), favorit, profil, dan dashboard organizer.
- Data event, tiket, transaksi, dan favorit tersimpan di Supabase.

## Setup Supabase

1. Buat project di [supabase.com](https://supabase.com) lalu salin **Project URL**
   dan **anon/publishable key** dari Settings > API.
2. Buka **SQL Editor**. Untuk database baru, jalankan berurutan:
   1. `supabase/schema.sql` — tabel, RLS dasar, trigger profil.
   2. `supabase/seed.sql` — 7 event demo + voucher.
   3. `supabase/p2_event_content.sql` — organizer + rating.
   4. `supabase/p2_notifications.sql` — tabel notifikasi + device token.
   5. `supabase/push_webhook.sql` (opsional, butuh Vault + Edge Function).
   6. **`supabase/security_hardening.sql` terakhir** — versi final RPC,
      grant kolom, RLS, voucher single-use, dan aturan pembayaran.

   File lama `p2_checkout_buyer.sql`, `notification_generation.sql`,
   `qty_voucher_stock.sql`, `storage.sql`, dan `account_deletion.sql` sudah
   digantikan oleh hardening. Detail dan urutan lengkap ada di
   [`docs/BACKEND_HARDENING.md`](docs/BACKEND_HARDENING.md).
3. (Disarankan untuk demo) Nonaktifkan konfirmasi email di
   Authentication > Providers > Email agar akun baru langsung dapat masuk.
4. Salin contoh konfigurasi lokal, lalu isi URL dan anon key:

```bash
cp supabase.local.example.json supabase.local.json
```

`supabase.local.json` sudah masuk `.gitignore` sehingga tidak ikut ter-commit.

5. Verifikasi koneksi, RLS, seed, dan RPC:

```powershell
pwsh -File tool/verify-supabase.ps1
```

6. Jalankan aplikasi:

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase.local.json
```

Alternatif tanpa file konfigurasi:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Tanpa kedua define tersebut, aplikasi menampilkan layar panduan setup.

### Akun organizer

Seed event belum memiliki organizer. Setelah mendaftar, jadikan akunmu
organizer lewat SQL Editor (ganti email sesuai akun yang dipakai):

```sql
update public.profiles set role = 'organizer'
where id = (select id from auth.users where email = '<EMAIL_ORGANIZER>');

update public.events
set organizer_id = (select id from auth.users where email = '<EMAIL_ORGANIZER>')
where id = '11111111-1111-4111-8111-000000000001';
```

Verifikasi akun organizer dan kepemilikan event:

```powershell
pwsh -File tool/verify-organizer.ps1
```

Check-in hanya dapat dilakukan organizer pemilik event, dan baru dibuka pada
tanggal event (zona `Asia/Jakarta`). Voucher demo: `EVENTKUY` dan `DISKON10`
(diskon Rp 25.000). Sesuai Syarat & Ketentuan, setiap kode voucher hanya bisa
dipakai **sekali secara global**; kuotanya selalu 1.

### Mode pembayaran

`security_hardening.sql` membuat tabel `app_settings` dengan
`payment_mode = 'simulation'` sebagai default:

- **simulation** — tiket langsung `paid` tanpa uang sungguhan. Dialog checkout
  menampilkan label “Mode simulasi: tidak ada dana yang ditarik.”
- **live** — checkout hanya membuat tiket/transaksi `pending`. Tiket menjadi
  `paid` setelah server pembayaran memanggil RPC `confirm_payment` memakai
  service role. Jangan aktifkan mode ini sebelum gateway + webhook signature
  siap:

```sql
update public.app_settings
set value = 'live', updated_at = now()
where key = 'payment_mode';
```

### Kamera & e-tiket PDF

Izin kamera sudah dideklarasikan untuk Android (`CAMERA`), iOS, dan macOS.
Di web, kamera hanya aktif pada `https://` atau `localhost`. Pemindaian kamera
didukung di Android, iOS, macOS, dan web; pada Windows/Linux gunakan tombol
**Masukkan Kode Manual**. Tombol **Unduh PDF** memakai share sheet di
Android/iOS dan mengunduh berkas langsung di browser.

### Gambar event

Taruh foto/poster event di **`assets/images/events/`** (sudah terdaftar di
`pubspec.yaml`). Penamaan: huruf kecil, tanpa spasi, misal
`konser-kampus.jpg`. Ukuran disarankan 1200 x 800 px.

Lalu isi kolom `image_url` di tabel `events` dengan salah satu bentuk:

- `assets/images/events/konser-kampus.jpg` — aset lokal, perlu rebuild
  aplikasi setiap kali gambar diganti.
- `https://<project>.supabase.co/storage/v1/object/public/event-images/...`
  — Supabase Storage, bisa diganti tanpa rebuild.

Untuk opsi kedua, jalankan `supabase/security_hardening.sql` (bagian 14).
File itu membuat bucket publik `event-images` dengan batas 5 MB,
MIME type JPEG/PNG/WebP, dan policy upload yang mewajibkan folder
`<user_id>/`. `supabase/storage.sql` lama sudah deprecated. Detail lengkap ada
di [`assets/images/events/README.md`](assets/images/events/README.md).

## Verifikasi

```bash
flutter analyze
flutter test
```

Widget test memakai `MockApiService`, sehingga tidak membutuhkan Supabase.

Smoke test backend membutuhkan `supabase.local.json` dan memeriksa:

- signup/login akun uji `eventkuy.smoke@gmail.com`,
- trigger profil otomatis,
- event dan voucher hasil seed,
- CRUD favorit dengan RLS,
- RPC `check_in_ticket` terpasang,
- user biasa tidak bisa mengubah `role` sendiri,
- organizer demo memiliki event seed,
- checkout dengan voucher, tiket/transaksi tersimpan,
- check-in hanya oleh organizer dan duplikasi ditolak.

```powershell
pwsh -File tool/verify-supabase.ps1
pwsh -File tool/verify-organizer.ps1
pwsh -File tool/verify-e2e.ps1
```

`verify-e2e.ps1` membuat satu tiket uji baru setiap kali dijalankan.

### Checklist P0

Lihat [`docs/P0_CHECKLIST.md`](docs/P0_CHECKLIST.md) untuk urutan setup,
E2E, dan pengujian kamera/PDF. Rincian hardening backend ada di
[`docs/BACKEND_HARDENING.md`](docs/BACKEND_HARDENING.md).

## Struktur

- `supabase/` — `schema.sql` (fondasi tabel/RLS/trigger), `seed.sql` (event + voucher), dan `security_hardening.sql` (migrasi final: RPC, grant kolom, RLS, storage, aturan bisnis).
- `assets/images/events/` — tempat menaruh foto/poster event milikmu.
- `lib/core/` — tema (`theme.dart`), breakpoint (`responsive.dart`), konfigurasi (`config.dart`), error (`errors.dart`).
- `lib/services/` — kontrak `EventKuyApi`, implementasi `SupabaseApi`, `TicketPdfService`, dan `MockApiService` untuk test.
- `lib/models/` — `Event`, `Ticket`, `CheckInResult`, `AppUser`, `Voucher`.
- `lib/providers/` — state management dengan Provider.
- `lib/screens/` — layar per fitur (auth, home, explore, event, checkout, ticket, favorite, profile, scan, organizer, setup).
- `DESIGN_SPEC.md` — acuan desain & kebutuhan teknis.
