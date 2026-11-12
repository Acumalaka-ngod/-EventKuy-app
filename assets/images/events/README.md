# Folder Gambar Event

Simpan foto/poster event kamu di folder ini.

## Aturan penamaan

- Huruf kecil, tanpa spasi, pakai `-` atau `_`.
  Contoh: `sound-of-tomorrow.jpg`, `workshop-fotografi-2026.png`
- Format yang didukung Flutter: `.jpg`, `.jpeg`, `.png`, `.webp`.
- Ukuran disarankan: **1200 x 800 px** (rasio 3:2), maksimal ± 500 KB
  supaya aplikasi tetap ringan.
- Satu event punya **satu poster utama** (`image_url`) dan boleh punya
  **beberapa foto galeri** (`image_urls`). Jangan pakai nama file yang sama
  untuk dua event berbeda.

## Cara memakainya

### 1. Lewat aset lokal (paling cepat, tanpa internet)

1. Taruh file di folder ini, misalnya `assets/images/events/konser-kampus.jpg`.
2. Isi kolom `image_url` di tabel `public.events` (Supabase Studio >
   Table Editor > events) dengan path aset:

   ```
   assets/images/events/konser-kampus.jpg
   ```

3. Jalankan ulang aplikasi (`flutter run`) atau build ulang web
   (`flutter build web`) agar aset baru ikut ter-bundle.

> Catatan: folder `assets/images/events/` sudah terdaftar di `pubspec.yaml`,
> jadi file baru langsung ikut ter-bundle tanpa mengubah `pubspec.yaml` lagi.
> Aset lokal **tidak bisa diganti saat aplikasi sudah berjalan** — perlu
> rebuild. Untuk mengganti gambar tanpa rebuild, pakai Supabase Storage.

### 2. Lewat Supabase Storage (disarankan untuk produksi)

1. Jalankan migrasi berikut sekali di SQL Editor Supabase:
   - `supabase/schema.sql` - tabel, view, RPC, dan RLS dasar.
   - `supabase/p2_event_content.sql` - tabel `organizers`, kolom rating.
   - `supabase/organizer_events.sql` - GRANT `select, insert, update`
     pada `public.events` untuk role `authenticated`.
   - `supabase/storage.sql` - bucket publik `event-images` + policy upload.
2. Pastikan akun organizer punya `profiles.role = 'organizer'`. Role ini
   dipakai policy Storage untuk mengizinkan upload.
3. Buka aplikasi sebagai organizer, lalu:
   **Profil -> Dashboard Organizer -> Buat Event Baru** (atau tap kartu
   event untuk mengedit). Pada bagian **Poster Event**, pilih
   **Pilih dari Galeri** atau **Ambil dari Kamera**. Poster diunggah ke
   bucket `event-images` saat tombol simpan ditekan.
4. URL publik otomatis disimpan ke `events.image_url`, jadi tidak perlu
   menyalin URL secara manual lewat Supabase Studio.

Upload dari aplikasi menerima **JPG, PNG, dan WebP** maksimal **5 MB**.
Format ditentukan dari isi file (magic bytes), jadi GIF yang diganti
ekstensinya tetap ditolak. File lama di Storage dihapus otomatis setelah
poster baru berhasil disimpan.

Upload manual lewat **Supabase Studio > Storage > event-images** tetap
bisa dipakai sebagai cadangan. Ambil **Public URL** file tersebut, lalu isi
`image_url` event dengan URL itu, contoh:

   ```
   https://<project>.supabase.co/storage/v1/object/public/event-images/konser-kampus.jpg
   ```

Gambar dari URL langsung tampil tanpa perlu build ulang aplikasi.

## Galeri foto di detail event (swipe)

Detail event menampilkan galeri yang bisa di-swipe:

- `image_url` = foto pertama (wajib, juga dipakai kartu di beranda).
- `image_urls` = foto tambahan (array teks, opsional).
- Urutan tampil: `image_url` lalu `image_urls`. Duplikat dan entri kosong
  otomatis dibuang (`Event.galleryImages`).
- Kalau hanya ada satu foto, counter `n / total` dan titik indikator
  disembunyikan. Tap foto membuka tampilan penuh (pinch-zoom).

Contoh mengisi lewat SQL Editor:

```sql
update public.events
set image_urls = array[
  'https://<project>.supabase.co/storage/v1/object/public/event-images/sound-2.jpg',
  'https://<project>.supabase.co/storage/v1/object/public/event-images/sound-3.jpg'
]
where id = '11111111-1111-4111-8111-000000000001';
```

Kolom `image_urls` ditambahkan oleh `supabase/schema.sql` (bagian migrasi
aditif). Untuk database yang sudah ada, jalankan ulang file itu atau cukup:

```sql
alter table public.events
  add column if not exists image_urls text[] not null default '{}';
```

## Bagaimana aplikasi membacanya

`lib/widgets/event_image.dart` menangani dua bentuk `image_url`:

| Nilai `image_url`            | Yang dipakai            |
| ---------------------------- | ----------------------- |
| diawali `assets/`            | `Image.asset` (bundled) |
| diawali `http`               | `CachedNetworkImage`    |
| kosong / tidak valid         | gambar fallback         |

## Strategi efisiensi (hybrid)

Untuk menjaga ukuran APK/web tetap kecil dan aplikasi tetap cepat:

| Kebutuhan | Sumber | Alasan |
|---|---|---|
| Gambar seed/demo (Sound of Tomorrow, dll.) | `assets/images/` (bundled) | Offline, tampil instan, testable |
| Gambar event produksi (organizer upload) | Supabase Storage `event-images` | Tidak ikut bundle, update tanpa rebuild |
| Fallback kalau URL gagal/error | `CachedNetworkImage` → placeholder ikon | UX tetap baik |

- `cached_network_image` menyimpan gambar Supabase ke **disk cache** → load kedua
  dan seterusnya instan, bahkan offline setelah pertama kali.
- `memCacheWidth/Height` di `EventImage` membatasi resolusi di memori →
  RAM tetap ringan.
- Gambar lokal di `assets/images/events/` **maksimal 100 KB** dan resolusi
  **≤ 1200 x 800 px** (WebP/JPG). Jangan bundle gambar besar.
- Jangan taruh gambar produksi di folder `assets/` — gunakan Supabase Storage
  agar tidak membesar APK.

## Gambar demo

Tujuh gambar demo (`event_sound.jpg`, `event_wtf.jpg`, dst.) sengaja tetap
disimpan di `assets/images/` agar data seed lama tidak berubah. Gambar baru
milikmu cukup ditaruh di folder `events/` ini (atau upload ke Supabase Storage
untuk produksi).
