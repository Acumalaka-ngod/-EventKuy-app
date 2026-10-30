# EVENTKUY

## LAPORAN PROGRESS PENGEMBANGAN APLIKASI MOBILE

Aplikasi Event Discovery dan E-Ticketing Berbasis Flutter

<br>

**Disusun oleh**

[Nama Mahasiswa]
NIM [NIM]
[Program Studi]
[Universitas]

**2026**

<br>

| Item | Keterangan |
|---|---|
| Judul proyek | EventKuy — aplikasi event discovery dan e-ticketing |
| Jenis dokumen | Laporan progress pengembangan aplikasi mobile |
| Versi dokumen | 1.0 |
| Tanggal status | 29 Oktober 2026 |
| Platform utama | Android (Flutter), dengan layout responsif untuk tablet, desktop, dan web |
| Repositori | https://github.com/Acumalaka-ngod/-EventKuy-app.git (branch `main`) |
| Lingkungan verifikasi | Flutter 3.47.5, Dart 3.13.4, Windows 11, Chrome headless |
| Status keseluruhan | Backend Supabase, auth, tiket, PDF, dashboard, dan check-in manual selesai; kamera/perangkat, APK, dan pembayaran riil belum selesai |

---

## Petunjuk Penggunaan Laporan

Laporan ini disusun mengikuti pedoman penulisan laporan proyek aplikasi mobile: setiap bab memuat konteks, keputusan perancangan, status implementasi, dan bukti yang sudah atau belum tersedia. Laporan berfokus pada **progress**, bukan klaim bahwa seluruh aplikasi telah selesai.

Penyesuaian judul bab dilakukan agar sesuai dengan teknologi proyek: bagian CMS dan Firebase pada pedoman diganti dengan backend Supabase dan Supabase Auth; bagian image capture diganti dengan QR/e-ticket; dan bagian laporan keuangan diganti dengan dashboard organizer. Struktur penomoran, gaya penulisan, tabel kebutuhan, tabel test case, dan aturan bukti tetap mengikuti pedoman.

Ketentuan status yang dipakai:

| Status | Arti |
|---|---|
| Selesai | Fitur berjalan dan dapat diverifikasi dari kode serta pengujian otomatis yang ada |
| Selesai (simulasi) | Alur lengkap, tetapi pembayaran masih disimulasikan |
| Berjalan | Sebagian sudah diimplementasikan, sebagian masih rencana |
| Rencana | Belum ada implementasi; baru berupa rancangan |
| Belum diuji | Implementasi ada, tetapi belum diuji pada lingkungan yang dimaksud |

Catatan bukti:

- Hasil pengujian yang dicantumkan pada Bab 9 berasal dari eksekusi nyata `flutter analyze`, `flutter test`, tiga script verifikasi Supabase, dan verifikasi UI web pada 28 Oktober 2026.
- Tangkapan layar aplikasi sudah dibuat di lingkungan verifikasi tetapi belum disalin ke repositori; hasil build APK dan pengujian perangkat fisik **belum tersedia**. Bagian yang belum memiliki berkas bukti ditandai sebagai placeholder dan wajib dilengkapi sebelum laporan akhir dikumpulkan.
- Seluruh diagram pada laporan ini masih berupa diagram teks sementara. Gambar final menyusul pada revisi laporan.
- Data event dan tiket berasal dari seed demo pada project Supabase, bukan data produksi.

---

## Daftar Isi

1. Project Planning and System Design
2. Development Environment Setup
3. Database and Backend Implementation
4. Authentication Implementation
5. REST API Integration
6. EventKuy Mobile UI Development
7. QR Code, E-Ticket, and Check-in
8. Organizer Dashboard and Reporting
9. Testing, Optimization, and Deployment

Checklist Bukti Implementasi Laporan
Daftar Referensi
Lampiran A — Struktur Proyek
Lampiran B — Konsistensi Field Model, Database, dan JSON
Lampiran C — Prosedur Reproduksi Verifikasi
Rencana Pengembangan Berikutnya

---

## Ringkasan Eksekutif

EventKuy adalah aplikasi mobile untuk menemukan event (konser, seminar, workshop, dan olahraga), menyimpan event favorit, membeli tiket, serta menampilkan e-ticket ber-QR. Frontend Flutter sudah terhubung ke backend Supabase untuk autentikasi, event, favorit, checkout, tiket, PDF, dashboard organizer, dan check-in.

Capaian utama per 28 Oktober 2026:

1. Seluruh tampilan utama telah diimplementasikan dan responsif pada mobile, tablet, dan desktop.
2. Autentikasi memakai Supabase Auth (email/password); sesi dikelola `supabase_flutter` dan profil dibaca dari tabel `profiles`.
3. Alur tiket berjalan: event dari Supabase, checkout dengan voucher lewat RPC `checkout`, tiket ber-QR, unduh PDF, serta check-in organizer lewat RPC `check_in_ticket`.
4. Dashboard organizer menampilkan statistik nyata dari Supabase dan hanya event milik organizer yang login.
5. `flutter analyze` menghasilkan **No issues found**, `flutter test` lulus **27 dari 27 pengujian**, dan `flutter build web --release` sukses.
6. Verifikasi UI web dengan headless Chrome mencakup login attendee/organizer, tiket, PDF, tiket tetap ada setelah login ulang, check-in manual, dan bottom bar detail event pada 390x844, 768x1024, serta 1400x900.
7. Yang belum selesai: pemindaian kamera di Chrome/Android, share sheet PDF di perangkat, build APK, dan pembayaran Midtrans masih simulasi.

| Area | Status | Bukti |
|---|---|---|
| Perencanaan dan desain | Selesai (dokumen) | DESIGN_SPEC.md, laporan ini |
| Lingkungan pengembangan | Selesai | `flutter doctor`, `flutter analyze`, `flutter test` |
| Database dan backend | Selesai (Supabase) | `supabase/schema.sql`, `seed.sql`, `tool/verify-supabase.ps1` |
| Autentikasi | Selesai (Supabase Auth) | Login/logout attendee dan organizer terverifikasi |
| Integrasi REST API | Selesai (Supabase) | `SupabaseApi`, RPC checkout/check-in |
| UI mobile | Selesai | Widget test 390–1400 px, verifikasi headless Chrome |
| QR, e-ticket, check-in | Berjalan | QR asli, PDF, check-in server; kamera pending |
| Dashboard organizer | Selesai (Supabase) | Statistik nyata, filter `organizerId` |
| Pengujian | Berjalan | 27 widget/unit test + 3 script verifikasi backend |
| Rilis | Berjalan | Build web sukses; APK dan perangkat pending |

---

## 1  Project Planning and System Design

Bagian ini mendefinisikan masalah, ruang lingkup, kebutuhan, dan rancangan aplikasi sebelum dan selama implementasi.

### 1.1  Introduction to EventKuy

EventKuy adalah aplikasi mobile berbasis Flutter untuk menemukan event, menyimpan event favorit, membeli tiket, dan menampilkan e-ticket ber-QR. Aplikasi menargetkan pengguna urban berusia 18–35 tahun yang aktif mencari hiburan dan pengembangan diri.

Ruang lingkup laporan difokuskan pada aplikasi Android sebagai target demonstrasi. Layout tablet, desktop, dan web tetap diresponsifkan, tetapi pengujian perangkat baru dilakukan pada emulator/Chrome selama pengembangan.

### 1.2  Project Background and Objectives

Pencarian event masih tersebar di banyak kanal (media sosial, situs penyelenggara, grup pesan) sehingga pengguna sulit membandingkan jadwal, harga, dan lokasi. Proses pembelian tiket juga sering terpisah dari proses menemukan event, dan bukti tiket mudah hilang.

Tujuan proyek:

1. Menyatukan penemuan event, penyimpanan favorit, pembelian tiket, dan e-ticket dalam satu aplikasi.
2. Menyediakan antarmuka yang konsisten dan responsif pada berbagai ukuran layar.
3. Menyiapkan arsitektur yang siap diintegrasikan dengan backend Supabase dan Midtrans.
4. Menyediakan alur check-in tiket melalui QR untuk panitia event.
5. Mendokumentasikan progres secara terukur melalui pengujian otomatis dan bukti implementasi.

### 1.3  Functional Requirements

Kebutuhan fungsional diberi ID agar dapat ditelusuri ke layar, endpoint, dan test case.

| ID | Requirement | Bukti Penerimaan | Status Saat Ini |
|---|---|---|---|
| FR-01 | Registrasi, login, logout | Supabase Auth + `AuthProvider` | Login/logout selesai; registrasi belum diuji |
| FR-02 | Melihat daftar event dan filter kategori/pencarian | Widget test Beranda/Jelajahi | Selesai |
| FR-03 | Melihat detail event lengkap | Widget test detail event | Selesai |
| FR-04 | Menyimpan dan menghapus event favorit | Tabel `favorites` + RLS | Selesai (Supabase); persistensi UI belum diuji |
| FR-05 | Checkout tiket dengan data pemesan | RPC `checkout` | Selesai (RPC); checkout UI belum diuji E2E |
| FR-06 | Voucher promo dan perhitungan biaya | RPC checkout + voucher seed | Selesai |
| FR-07 | Memilih metode pembayaran | Widget test checkout | Selesai (simulasi) |
| FR-08 | E-ticket ber-QR | Widget test tiket | Selesai |
| FR-09 | Check-in tiket | RPC `check_in_ticket` + scan manual | Selesai (manual); kamera pending |
| FR-10 | Filter tiket: Semua/Aktif/Selesai | Widget test tiket | Selesai |
| FR-11 | Profil pengguna dan logout | Widget test navigasi + Supabase Auth | Selesai (Supabase) |
| FR-12 | Dashboard organizer | Widget test organizer + statistik Supabase | Selesai (Supabase) |
| FR-13 | Notifikasi push | Belum ada | Rencana |
| FR-14 | Unduh e-ticket PDF | `pdf` + `printing`, unduhan web | Selesai (web) |
| FR-15 | Pembayaran riil (Midtrans) | Belum ada | Rencana |

### 1.4  Non-Functional Requirements

| Area | Target | Bukti atau Status |
|---|---|---|
| Keamanan | Tidak ada kredensial sensitif di repositori; token tidak ditampilkan di UI | Supabase Auth + RLS; service role key tidak dipakai aplikasi |
| Usability | Validasi form jelas, state loading/empty/error tersedia | Error Supabase dipetakan ke pesan pengguna |
| Responsif | Mobile, tablet, desktop tanpa overflow | Diuji otomatis pada 390, 768, 1080, 1366, 1400 px |
| Kinerja | Daftar event dan gambar tidak membebani perangkat | Gambar memakai `cached_network_image`/`Image.asset` dengan fallback |
| Maintainability | Pemisahan layer UI, provider, model, service | Struktur `core`, `models`, `providers`, `screens`, `services`, `widgets` |
| Kompatibilitas | Android sebagai target utama; Flutter stabil | Flutter 3.47.5, Dart 3.13.4 |
| Kualitas kode | Tidak ada issue analyzer | `flutter analyze`: No issues found |
| Pengujian | Alur utama tercakup widget test dan verifikasi backend | 27/27 test lulus + 3 script backend pada 28 Oktober 2026 |

### 1.5  Application Features and User Roles

| Peran | Fitur Utama | Akses | Status |
|---|---|---|---|
| Pengguna (pengunjung event) | Beranda, jelajahi, favorit, detail, checkout, tiket, profil | 5 tab utama | Selesai (Supabase) |
| Pengguna sebagai panitia/organizer | Dashboard organizer, statistik event, scan QR check-in | Menu di layar Profil | Selesai; kamera pending |
| Administrator backend | Mengelola event, tiket, dan transaksi | Supabase Studio | Selesai (Supabase Studio) |

Otorisasi diterapkan di server melalui Supabase Row Level Security: pengguna
hanya membaca tiket/transaksi/favorit miliknya, organizer hanya mengelola event
miliknya, dan check-in divalidasi oleh RPC `check_in_ticket`. Panel admin web
kustom tidak dibuat; pengelolaan data memakai Supabase Studio.

### 1.6  Technology Stack Overview

| Lapisan | Teknologi | Versi/Keterangan | Kegunaan |
|---|---|---|---|
| Mobile | Flutter | 3.47.5 (stable) | UI dan logika aplikasi |
| Bahasa | Dart | 3.13.4 | Implementasi |
| State | provider | ^6.1.5 | State management `ChangeNotifier` |
| Penyimpanan sesi | Supabase Auth | `supabase_flutter` ^2.18.3 | Sesi login dan refresh token |
| QR | qr_flutter | ^4.1.0 | Render QR e-ticket |
| Gambar | cached_network_image | ^3.4.1 | Cache gambar jaringan |
| Format | intl | ^0.20.2 | Format tanggal Indonesia |
| Font | Manrope dan DM Sans | 9 berkas TTF | Tipografi aplikasi |
| HTTP/API | supabase_flutter | ^2.18.3 | Auth, PostgREST, dan RPC |
| Kamera | mobile_scanner | ^7.0.1 | Preview kamera dan pemindaian QR |
| PDF | pdf, printing | ^3.13.1, ^5.15.1 | Membuat dan mengunduh e-ticket |
| Media | image_picker | ^1.1.2 | Terpasang, belum dipakai |
| Web | webview_flutter, url_launcher | ^4.13.0, ^6.3.2 | Terpasang, belum dipakai |
| Backend | Supabase (PostgreSQL, Auth, RLS, RPC) | Project aktif | Database, autentikasi, otorisasi |
| Pembayaran | Midtrans | Simulasi | Payment gateway belum diintegrasikan |
| Distribusi | Play Store / web | Build web sukses | Rilis Android pending |

Catatan: `http` tidak lagi dipakai langsung; akses data melewati
`SupabaseApi`. `mobile_scanner` dipakai di layar scan, sedangkan `pdf` dan
`printing` dipakai untuk e-ticket PDF.

### 1.7  High-Level System Architecture

Arsitektur saat ini (Supabase):

```text
Splash / Auth screens
        |
MainNavigation (5 tab)
        |
Screens  ->  Providers (ChangeNotifier)  ->  SupabaseApi
        |            |                          |
        |            +--> Supabase Auth session |
        |                                       +--> PostgreSQL + RLS
        +--> Widgets bersama                    +--> RPC checkout/check-in
                                                +--> assets/images + fallback picsum
```

Alur pembayaran masih disimulasikan di aplikasi, sedangkan pembuatan tiket dan
perubahan status dilakukan oleh RPC Supabase. Prinsip yang diterapkan: widget
tidak memanggil sumber data secara langsung; provider menjadi perantara; model
memiliki `fromJson`/`toJson`; konfigurasi URL dan kunci publishable dipusatkan
di `lib/core/config.dart` dan diisi lewat `--dart-define-from-file`.

**Gambar 1.** Arsitektur sistem EventKuy saat ini dan target. Status: placeholder diagram teks; gambar final menyusul.

### 1.8  Application Use Case Diagram

Aktor dan use case utama:

| Aktor | Use Case |
|---|---|
| Pengguna | Registrasi, login, logout, melihat beranda, mencari event, memfilter kategori, melihat detail, menyimpan favorit, checkout, memakai voucher, memilih pembayaran, melihat e-ticket, check-in tiket, mengubah profil (rencana) |
| Panitia/Organizer | Membuka dashboard organizer, melihat statistik event, membuka detail event, scan QR check-in |
| Administrator (Supabase Studio) | Mengelola master event, tiket, dan transaksi melalui Supabase Studio |

Prasyarat: use case pembelian dan tiket memerlukan status login melalui Supabase Auth. Use case check-in memerlukan tiket berstatus `paid` dan akun organizer pemilik event.

**Gambar 2.** Use case diagram EventKuy. Status: placeholder; diagram final menyusul.

### 1.9  Application Navigation Flow

```text
Splash
 └─ auto-login? -> Beranda / Login
Login <-> Register
MainNavigation (5 tab)
 ├─ 0 Beranda  -> Detail Event -> Checkout -> Dialog Sukses -> Tiket Saya
 ├─ 1 Jelajahi -> Detail Event
 ├─ 2 Tiket Saya
 ├─ 3 Favorit  -> Detail Event
 └─ 4 Profil   -> Dashboard Organizer -> Scan QR
                -> Konfirmasi Logout
Bottom sheet: Pilih Kota
```

Daftar tampilan dan status implementasi:

| No | Tampilan | Status | Bukti |
|---|---|---|---|
| 1 | Splash | Selesai | Widget test boot |
| 2 | Login | Selesai (Supabase Auth) | Verifikasi UI web |
| 3 | Register | Selesai (Supabase Auth) | Kode implementasi |
| 4 | Shell navigasi responsif | Selesai | Widget test 3 breakpoint |
| 5 | Beranda | Selesai (Supabase) | Widget test navigasi |
| 6 | Jelajahi | Selesai (Supabase) | Widget test navigasi |
| 7 | Tiket Saya | Selesai | Widget test 2 ukuran + PDF |
| 8 | Favorit | Selesai (Supabase) | Widget test navigasi |
| 9 | Profil | Selesai | Widget test navigasi |
| 10 | Detail Event | Selesai | Widget test 3 ukuran + regression bar |
| 11 | Checkout | Selesai (pembayaran simulasi) | Widget test 3 ukuran |
| 12 | Dialog sukses pembayaran | Selesai (simulasi) | Kode dan alur |
| 13 | Bottom sheet kota dan logout | Selesai | Kode dan alur |

**Gambar 3.** Navigation flowchart EventKuy. Status: placeholder; gambar final menyusul.

### 1.10  UI/UX Wireframe Design

Desain mengikuti prototipe Figma dan dituangkan dalam `DESIGN_SPEC.md`. Arah visual: palet violet dengan aksen coral, tipografi Manrope untuk heading dan DM Sans untuk body, kartu membulat, dan gradien violet pada elemen branding.

Token visual utama:

| Token | Nilai |
|---|---|
| Warna primer | `#6657EA` (violet) |
| Warna primer gelap | `#4B3FC3` |
| Warna aksen | `#FF6B6F` (coral) |
| Warna teks utama | `#17152C` |
| Warna teks sekunder | `#77758A` |
| Latar kanvas | `#F7F7FB` |
| Border | `#E8E7EF` |
| Gradien utama | `#7263F4 -> #5848D7` |
| Gradien tiket | `#33278A -> #6958E8` |
| Gradien splash/auth | `#33278C -> #6454EB -> #9F56DF` |

Aturan responsif yang diterapkan:

| Breakpoint | Lebar | Navigasi | Grid event | Padding konten |
|---|---|---|---|---|
| Mobile | < 720 px | Bottom bar mengambang 72 px | 2 kolom | 18 px |
| Tablet | 720–1100 px | Rail ikon 88 px | 3 kolom | 28 px |
| Desktop | > 1100 px | Sidebar 240 px | 4 kolom | 32 px |

Lebar konten maksimum 1200 px dan selalu dipusatkan pada layar besar. Kartu tiket memakai 1/2/3 kolom sesuai lebar.

**Gambar 4.** Wireframe dan token UI EventKuy. Status: placeholder; mockup final menyusul.

### 1.11  Database Entity Relationship Diagram (ERD)

Database sudah diimplementasikan pada Supabase (PostgreSQL). Entitas utama:

| Entitas | Atribut Inti | Keterangan |
|---|---|---|
| auth.users | id, email, encrypted_password, created_at | Dikelola Supabase Auth |
| profiles | id, name, role, avatar_url, created_at | Profil publik; `role` pengguna/organizer/admin |
| events | id, organizer_id, title, description, date, location, price, quota, image_url, category, tags, time_range | `organizer_id` mengacu ke `auth.users` |
| tickets | id, code, event_id, user_id, status, created_at | Status `pending`, `paid`, `checked_in` |
| transactions | id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status, created_at | Dibuat RPC checkout |
| favorites | id, user_id, event_id, created_at | Unik per pasangan user/event |
| vouchers | code, discount, active_from, active_to, quota | Voucher server-side |

Relasi utama: satu user memiliki banyak ticket, transaction, dan favorite; satu event memiliki banyak ticket dan transaction; satu transaction menghasilkan satu ticket; satu ticket terkait satu event. RLS membatasi akses sesuai pemilik data dan organizer event.

Catatan konsistensi: model Flutter memakai `eventId` dan `eventTitle` pada `Ticket`, serta `imageUrl` dan `timeRange` pada `Event`. Penamaan kolom database dan JSON diselaraskan melalui mapping (lihat Lampiran B).

**Gambar 5.** ERD EventKuy. Status: implementasi Supabase, diagram gambar final menyusul.

### 1.12  REST API Endpoint Specification

Aplikasi tidak memakai REST API kustom. Akses data memakai Supabase PostgREST
dan RPC dengan sesi Supabase Auth:

| Operasi | Akses Supabase | Kegunaan | Status |
|---|---|---|---|
| Register/login/logout | Supabase Auth | Sesi pengguna | Selesai |
| Daftar event | `events.select()` | Beranda/Jelajahi | Selesai |
| Favorit | `favorites` select/insert/delete | Favorit pengguna | Selesai |
| Checkout | RPC `checkout` | Transaksi + tiket + voucher | Selesai |
| Tiket pengguna | `tickets.select()` | Tiket Saya | Selesai |
| Tiket event | `tickets.select()` filter event | Dashboard organizer | Selesai |
| Check-in | RPC `check_in_ticket` | Validasi organizer | Selesai |
| Pembayaran | simulasi di aplikasi | Midtrans belum | Simulasi |

Setiap request membawa sesi Supabase; RLS memverifikasi kepemilikan data di
server. Service role key tidak dipakai aplikasi.

---

## 2  Development Environment Setup

Bagian ini mencatat lingkungan pengembangan yang benar-benar dipakai dan hasil verifikasinya.

### 2.1  Creating the EventKuy Flutter Project

Proyek dibuat dengan Flutter CLI. Folder proyek, nama paket Dart (`eventkuy`), dan `applicationId` (`com.eventkuy.app`) memakai identitas EventKuy; nama brand yang tampil di UI, Android, iOS, dan web juga **EventKuy**.

```bash
flutter create eventkuy
cd eventkuy
flutter pub get
flutter run -d chrome
```

Informasi versi aplikasi: `version: 1.0.0+1` pada `pubspec.yaml`.

### 2.2  Installing Required Flutter Packages

Dependensi dipasang sesuai kebutuhan. Status pemakaian diperiksa langsung dari impor kode:

| Paket | Versi | Status | Kegunaan |
|---|---|---|---|
| provider | ^6.1.5 | Dipakai | State management |
| supabase_flutter | ^2.18.3 | Dipakai | Auth, PostgREST, RPC |
| qr_flutter | ^4.1.0 | Dipakai | QR e-ticket |
| intl | ^0.20.2 | Dipakai | Format tanggal |
| cached_network_image | ^3.4.1 | Dipakai | Cache gambar |
| mobile_scanner | ^7.0.1 | Dipakai | Preview kamera dan scan QR |
| pdf | ^3.13.1 | Dipakai | Membuat e-ticket PDF |
| printing | ^5.15.1 | Dipakai | Share sheet/unduhan PDF |
| image_picker | ^1.1.2 | Belum dipakai | Persiapkan unggah gambar |
| url_launcher | ^6.3.2 | Belum dipakai | Persiapkan tautan eksternal |
| webview_flutter | ^4.13.0 | Belum dipakai | Persiapkan halaman web |
| cupertino_icons | ^1.0.8 | Dipakai | Ikon bawaan |

`flutter_lints ^6.0.0` dipakai sebagai aturan analisis statis.

### 2.3  Organizing the Flutter Project Structure

```text
lib/
  main.dart
  core/
    config.dart
    responsive.dart
    theme.dart
  models/
    event.dart
    ticket.dart
    user.dart
  providers/
    auth_provider.dart
    event_provider.dart
    favorite_provider.dart
    ticket_provider.dart
  screens/
    auth/
    checkout/
    event/
    explore/
    favorite/
    home/
    organizer/
    profile/
    scan/
    splash/
    ticket/
    main_navigation.dart
  services/
    api_service.dart
    mock_api_service.dart
    supabase_api.dart
    ticket_pdf_service.dart
  widgets/
    app_logo.dart
    app_search_bar.dart
    category_chip.dart
    custom_button.dart
    event_card.dart
    event_image.dart
    hero_banner.dart
    payment_option.dart
    section_header.dart
    ticket_item.dart
```

Pemisahan ini memudahkan penggantian `MockApiService` dengan `SupabaseApi` tanpa mengubah widget; `EventKuyApi` menjadi kontrak bersama.

### 2.4  Configuring Environment Variables

Konfigurasi global berada di `lib/core/config.dart` dan diisi saat run/build:

```dart
class AppConfig {
  static const String appName = 'EventKuy';
  static const String applicationId = 'com.eventkuy.app';
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static const bool midtransIsProduction = false;
}
```

Contoh perintah:

```powershell
flutter run --dart-define-from-file=supabase.local.json
flutter build web --release --dart-define-from-file=supabase.local.json
```

Catatan:

- `supabase.local.json` berisi URL, anon key, dan kredensial akun demo; file ini di-ignore dan tidak di-commit.
- Service role key tidak dipakai aplikasi.
- `midtransIsProduction` masih `false`; pembayaran disimulasikan lewat RPC checkout.

### 2.5  Flutter SDK and Toolchain Verification

Hasil `flutter doctor` pada 22 Oktober 2026:

```text
[√] Flutter (Channel stable, 3.47.5, on Microsoft Windows 11, locale en-ID)
[√] Windows Version (Windows 11 or higher, 26H2, 2009)
[√] Android toolchain (Android SDK version 36.1.0)
[√] Chrome - develop for the web
[X] Visual Studio - develop Windows apps (tidak terpasang)
[√] Connected device (3 tersedia)
[√] Network resources
```

Visual Studio tidak terpasang, tetapi tidak menghambat target Android dan web. Pengujian perangkat Android fisik belum dilakukan; perangkat yang tersedia baru berupa target desktop/web.

### 2.6  Android and iOS Configuration

| Item | Nilai | Status |
|---|---|---|
| Android label | `EventKuy` | Selesai |
| applicationId | `com.eventkuy.app` | Disamakan dengan identitas EventKuy |
| compileSdk/minSdk/targetSdk | Mengikuti `flutter.*` bawaan | Selesai |
| Izin INTERNET Android | Ada di manifest utama | Selesai |
| Izin kamera Android | `android.permission.CAMERA` | Selesai |
| iOS display name | `EventKuy` | Selesai |
| iOS camera usage description | `NSCameraUsageDescription` | Selesai |

### 2.7  Version Control Setup

| Item | Nilai |
|---|---|
| Repositori | `https://github.com/Acumalaka-ngod/-EventKuy-app.git` |
| Branch aktif | `main` |
| Commit terakhir | `b503219` — mengabaikan artefak build Gradle |
| Perubahan belum di-commit | Redesign UI, integrasi Supabase, test, dan dokumen |
| Artefak build | Diabaikan melalui `.gitignore` |

Perubahan redesign, backend Supabase, dan perbaikan terbaru belum di-commit.
Commit dan push perlu dilakukan setelah verifikasi visual oleh pemilik proyek.

### 2.8  Testing Environment

| Perintah | Hasil |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 27/27 lulus |
| `flutter build web --release` | Sukses dengan `--dart-define-from-file=supabase.local.json` |
| `flutter doctor` | Satu peringatan (Visual Studio tidak terpasang) |
| `flutter run -d chrome` | Tersedia sebagai target pengembangan |

Ukuran layar yang diuji otomatis: 390x844 (HP), 768x1024 (tablet), 1080x800 (laptop kecil), 1366x620 (jendela Chrome pendek), 1400x900 (desktop).

---

## 3  Database and Backend Implementation

**Status: Selesai (Supabase).** Skema, RLS, trigger, RPC checkout/check-in, dan seed sudah diterapkan pada project Supabase aktif. `MockApiService` hanya dipakai untuk test.

### 3.1  Designing the EventKuy Database

Database memakai PostgreSQL Supabase. Primary key memakai UUID, nilai uang memakai `numeric(12,2)`, dan status tiket dibatasi pada `pending`, `paid`, serta `checked_in`. Tabel `profiles` terhubung ke `auth.users` dan diisi otomatis oleh trigger `handle_new_user`.

Alasan pemilihan: kebutuhan relasional (user, event, tiket, transaksi, favorit) lebih mudah dijaga dengan foreign key, constraint, dan RLS dibanding penyimpanan dokumen.

### 3.2  Implemented Tables

| Tabel | Kolom Utama | Constraint |
|---|---|---|
| profiles | id, name, role, avatar_url, created_at | FK ke `auth.users`, role `pengguna`/`organizer`/`admin` |
| events | id, organizer_id, title, description, date, location, price, quota, image_url, category, tags, time_range, created_at | FK organizer, harga/kuota >= 0 |
| tickets | id, code, event_id, user_id, status, created_at | code unik, FK event/user |
| transactions | id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status, created_at | FK user/event/ticket, satu tiket satu transaksi |
| favorites | id, user_id, event_id, created_at | unik per pasangan user/event |
| vouchers | code, discount, active_from, active_to, quota | code unik |

Model Flutter (`Event`, `Ticket`, `AppUser`) sudah disesuaikan dengan UUID dan `snake_case`. Detail konsistensi field ada pada Lampiran B.

### 3.3  Relationships and Constraints

- `tickets.event_id` mengacu ke `events.id`; `tickets.user_id` mengacu ke `auth.users.id`.
- `transactions.ticket_id` mengacu ke `tickets.id`; satu transaksi menghasilkan satu tiket.
- `favorites` memakai kunci unik `(user_id, event_id)`.
- Harga, biaya layanan, dan diskon tidak boleh negatif; total dihitung di RPC.
- Status tiket hanya boleh berubah dari `pending` ke `paid` ke `checked_in`.

### 3.4  Authorization and Data Ownership

Otorisasi diterapkan dengan Supabase Row Level Security:

- Pengguna hanya dapat membaca tiket, transaksi, dan favorit miliknya.
- Organizer hanya dapat mengelola event miliknya; RPC check-in menolak akun lain.
- Check-in divalidasi di server melalui `check_in_ticket`; aplikasi tidak mengubah status tiket secara lokal.
- Kunci rahasia (service role key) tidak dipakai aplikasi; aplikasi hanya memakai publishable/anon key.

### 3.5  Seed Data

Seed berisi 7 event (Sound of Tomorrow, We The Fest 2025, Photography Workshop, Future of Technology, Jakarta Running Festival, UI/UX Design Workshop, Digital Marketing Summit) dan voucher `EVENTKUY`. Seed idempoten dan sudah dijalankan pada project aktif.

### 3.6  Testing Results

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| DB-01 | Skema dan seed dijalankan pada database kosong | Semua tabel terbentuk, 7 event tersedia | Lulus | Selesai |
| DB-02 | Insert tiket dengan event_id tidak valid | Ditolak foreign key | Constraint FK tersedia; insert invalid belum diuji terpisah | Sebagian |
| DB-03 | Pengguna A membaca tiket pengguna B | Ditolak atau kosong | Lulus (RLS) | Selesai |
| DB-04 | Check-in ganda pada tiket yang sama | Ditolak | Lulus | Selesai |

Verifikasi dijalankan lewat `tool/verify-supabase.ps1`, `tool/verify-organizer.ps1`, dan `tool/verify-e2e.ps1` pada 28 Oktober 2026. Rincian hasil ada pada bagian 9.2.

---

## 4  Authentication Implementation

**Status: Selesai (Supabase Auth).** Login, logout, registrasi, dan pemulihan sesi memakai Supabase Auth. Profil diambil dari tabel `profiles`.

### 4.1  Current Authentication Flow

```text
Splash
  -> AuthProvider.tryAutoLogin()
     -> Supabase.instance.client.auth.currentUser
        -> ada: baca profil -> MainNavigation
        -> tidak: LoginScreen
LoginScreen -> signInWithPassword -> baca profil -> MainNavigation
RegisterScreen -> signUp(name, email, password) -> sesi -> MainNavigation
Logout -> signOut -> LoginScreen
```

### 4.2  Login Screen

Layar login berisi email, password dengan toggle visibilitas, checkbox "Ingat saya", tautan "Lupa Password?", tombol "Masuk Sekarang", tombol Google/Apple (belum berfungsi), dan tautan registrasi. Validasi memeriksa field wajib dan panjang password minimal 8 karakter. Kredensial demo tidak ditanam di kode; nilai diisi dari `supabase.local.json` saat verifikasi.

### 4.3  Register Screen

Form registrasi mencakup nama, email, password, konfirmasi password, dan persetujuan syarat & ketentuan. Validasi yang berjalan:

1. Semua field wajib harus terisi.
2. Konfirmasi password harus sama.
3. Checkbox syarat & ketentuan harus dicentang.

Setelah `signUp` sukses dan sesi tersedia, pengguna langsung masuk. Konfirmasi email dinonaktifkan di project demo agar alur dapat diuji.

### 4.4  AuthProvider Implementation

`AuthProvider` memakai `Supabase.instance.client.auth`:

- `tryAutoLogin()` membaca `currentUser` lalu memuat profil.
- `login()` memanggil `signInWithPassword`.
- `register()` memanggil `signUp` dengan metadata `name`.
- `resetPassword()` memanggil `resetPasswordForEmail`.
- `logout()` memanggil `signOut` dan membersihkan state lokal.

Sesi disimpan dan di-refresh oleh `supabase_flutter`. Email diambil dari sesi auth, bukan dari tabel `profiles`; password di-hash oleh Supabase Auth.

### 4.5  Security Notes

- Aplikasi hanya memakai publishable/anon key; service role key tidak boleh masuk aplikasi.
- RLS membatasi data per pengguna dan organizer.
- `supabase.local.json` di-ignore dan tidak di-commit.
- Reset password memakai alur email Supabase; pengujian email belum dilakukan.

### 4.6  Authentication Test Results

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| AUTH-01 | Login attendee dengan data benar | Masuk ke MainNavigation | Lulus (headless Chrome) | Selesai |
| AUTH-02 | Login dengan field kosong | Pesan validasi, tidak berpindah layar | Validasi form tersedia | Belum diuji otomatis |
| AUTH-03 | Registrasi dengan konfirmasi password berbeda | Pesan kesalahan | Validasi form tersedia | Belum diuji otomatis |
| AUTH-04 | Sesi dipulihkan setelah reload | Langsung ke beranda | Mekanisme `tryAutoLogin` tersedia; reload belum diuji | Sebagian |
| AUTH-05 | Logout lalu login kembali | Kembali ke login, tiket tetap ada | Lulus (headless Chrome) | Selesai |
| AUTH-06 | Login organizer | Dashboard organizer terbuka | Lulus (headless Chrome) | Selesai |

Bukti otomatis: `widget_test.dart` menguji boot ke splash/panduan setup.
Pengujian login/logout nyata dilakukan manual melalui UI web pada 28 Oktober
2026; validasi form login/registrasi belum tercakup widget test.

---

## 5  REST API Integration

**Status: Selesai (Supabase).** Aplikasi memakai `SupabaseApi` untuk PostgREST dan RPC. `MockApiService` hanya dipakai oleh test.

### 5.1  SupabaseApi

`lib/services/supabase_api.dart` mengimplementasikan `EventKuyApi`:

- `fetchEvents()` membaca tabel `events` terurut tanggal.
- `fetchTickets()` membaca tiket milik user beserta judul event.
- `fetchEventTickets(eventId)` dipakai dashboard organizer.
- `checkout()` memanggil RPC `checkout`.
- `checkIn()` memanggil RPC `check_in_ticket`.
- `fetchFavoriteIds()`, `addFavorite()`, `removeFavorite()` mengelola tabel `favorites`.
- `fetchVoucher()` membaca voucher aktif.

`MockApiService` tetap tersedia untuk widget test deterministik dan bukan jalur runtime.

### 5.2  Data Access Mapping

| Layar | Akses | Data |
|---|---|---|
| Beranda/Jelajahi | `events.select()` | Daftar event, filter kategori/kota di klien |
| Detail | objek event dari daftar | Detail event |
| Favorit | `favorites` select/insert/delete | Sinkronisasi favorit per user |
| Checkout | RPC `checkout` | Transaksi + tiket + diskon voucher |
| Tiket Saya | `tickets.select()` | Tiket pengguna |
| Scan | RPC `check_in_ticket` | Validasi check-in oleh organizer |
| Organizer | `events` + `tickets` | Statistik dan tiket per event |

### 5.3  JSON Serialization

Model memakai `snake_case` dari Supabase dan `camelCase` di Dart. ID event/tiket bertipe `String` (UUID), harga memakai `num`/`double`, dan tanggal diparse dari `date`/`created_at`. Mapping eksplisit menjaga konsistensi tipe.

### 5.4  Error Handling

`lib/core/errors.dart` memetakan error Supabase/PostgREST menjadi pesan pengguna, misalnya voucher tidak valid, kuota habis, tiket tidak ditemukan, tiket sudah check-in, dan sesi login tidak ditemukan. Detail teknis tidak ditampilkan di UI.

### 5.5  Current Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| API-01 | GET daftar event | Data ter-parse | Lulus (`verify-supabase.ps1`) | Selesai |
| API-02 | Checkout dengan voucher valid | Total berkurang Rp 25.000 | Lulus (`verify-e2e.ps1`) | Selesai |
| API-03 | Checkout dengan voucher salah | Pesan error, total tetap | Lulus (`verify-e2e.ps1`) | Selesai |
| API-04 | Akses tanpa sesi | Ditolak RLS/RPC | Lulus (`verify-e2e.ps1`) | Selesai |
| API-05 | Timeout/jaringan bermasalah | Pesan error dan opsi coba lagi | Pesan error tersedia; timeout belum diuji | Sebagian |

Verifikasi backend dijalankan pada 28 Oktober 2026 dengan tiga script di
`tool/`. Rincian hasil ada pada bagian 9.2.

---

## 6  EventKuy Mobile UI Development

**Status: Selesai (terhubung Supabase).** Seluruh layar utama sudah diimplementasikan, memakai data Supabase, dan diuji bebas overflow pada beberapa ukuran layar.

### 6.1  Application Theme

Tema didefinisikan di `lib/core/theme.dart` dengan `ThemeData` Material 3, font DM Sans sebagai default, Manrope untuk heading, serta token warna, radius, shadow, dan gradien. Komponen bawaan (input, tombol, chip, snackbar, checkbox) sudah diselaraskan agar tampilan konsisten.

### 6.2  Main Navigation

`MainNavigation` mengelola 5 tab: Beranda, Jelajahi, Tiket, Favorit, dan Profil. Isi tab disimpan dengan `IndexedStack` agar state tidak hilang saat berpindah tab. Navigasi berubah otomatis:

- Mobile: bottom bar mengambang dengan ikon, label, dan pill aktif.
- Tablet: rail 88 px tanpa label (tooltip sebagai pengganti).
- Desktop: sidebar 240 px dengan logo, label menu, dan footer versi.

Badge coral menampilkan jumlah tiket dan favorit (maksimum "9+").

### 6.3  Splash Screen

Splash memakai latar gradien, logo EventKuy, tagline "TEMUKAN • IKUTI • HADIRI", dan teks versi. Animasi scale + fade berjalan sekitar 1,1 detik, dilanjutkan auto-login dan transisi fade ke Login atau Beranda.

### 6.4  Beranda

Konten: top bar "LOKASI SAYA" dengan pemilih kota (bottom sheet), sapaan pengguna, search bar, hero banner event unggulan, kategori, dan section "Event Terdekat Untukmu" berisi grid kartu event. Pull-to-refresh tersedia. Aksi pada kartu membuka detail event.

Pemilih kota berisi opsi Jakarta, Bandung, Surabaya, Yogyakarta, dan "Semua Kota"; pilihan memfilter daftar event pada layar Beranda/Jelajahi.

### 6.5  Jelajahi

Konten: judul "Jelajahi Event", search bar, chip kategori yang dapat digulir horizontal, quick filter Semua/Terpopuler/Terdekat dengan jumlah event, serta daftar event. Di mobile dipakai kartu horizontal; di layar lebar dipakai grid poster. Empty state menyediakan tombol reset pencarian.

Perbaikan terbaru: pada layar sempit, quick filter disusun vertikal (chip dapat digulir) agar tidak overflow.

### 6.6  Detail Event

Konten: hero image dengan tombol kembali, bagikan, dan favorit; indikator "1 / 4 Foto"; chip kategori dan rating "4.9 (320 ulasan)"; judul; kartu tanggal/waktu; kartu lokasi berisi alamat lengkap; kartu organizer dengan tombol "Ikuti"; section "Tentang Acara"; tagar; serta buy bar sticky berisi "Harga Tiket" dan tombol "Daftar & Beli Tiket".

Buy bar memakai `Scaffold.bottomNavigationBar`, bukan `bottomSheet`, agar selebar viewport. Konten bar dibatasi 860 px dan padding body disesuaikan supaya konten terakhir tidak tertutup. Regression test `event-detail-buy-bar` memeriksa tinggi < 160 px, lebar sama dengan viewport, dan judul event tetap dapat di-hit-test pada 390x844, 768x1024, dan 1400x900.

Tombol bagikan baru menampilkan snackbar; native share belum diimplementasikan. Tombol organizer menampilkan snackbar konfirmasi mengikuti.

### 6.7  Checkout

Konten: step indicator (Pilih, Bayar, E-Tiket), kartu ringkasan event, form informasi pemesan (nama, email, nomor WhatsApp), tiga metode pembayaran (GoPay, Virtual Account, Kartu Kredit/Debit), voucher, rincian biaya (harga tiket, biaya layanan Rp 2.500, diskon), total, dan tombol "Bayar Sekarang".

Perilaku:

- Voucher valid: `EVENTKUY` dan `DISKON10`, diskon Rp 25.000; validasi dan perhitungan dilakukan RPC `checkout` di server.
- Voucher salah menampilkan pesan error dari server.
- Tombol bayar menampilkan loading, memanggil RPC `checkout` yang membuat transaksi dan tiket berstatus `paid`, lalu menampilkan dialog sukses dengan TICKET ID dan tombol "Lihat Tiket Saya".
- Layout desktop memakai dua kolom (form di kiri, ringkasan total di kanan); mobile satu kolom.
- Pembayaran masih simulasi: tidak ada panggilan ke Midtrans dan tidak ada uang yang berpindah.

### 6.8  Tiket Saya

Konten: judul "Tiket & Pass Saya", tab Semua/Aktif/Selesai dengan jumlah, kartu e-ticket bergaya boarding pass (header gradien, badge status, judul event, jadwal, perforasi, QR, TICKET ID, pemilik tiket, dan tombol "Unduh PDF"), serta empty state.

Data tiket dibaca dari Supabase. QR dihasilkan dari kode tiket (`EVK-...`) yang dibuat database dan dapat dipindai. Tombol "Unduh PDF" memakai `TicketPdfService` + `Printing.sharePdf`: di web file terunduh dengan nama `EventKuy-<kode>.pdf`; di mobile tombol membuka share sheet (belum diuji di perangkat).

Grid tiket memakai 1/2/3 kolom dengan tinggi adaptif terhadap skala teks agar tidak overlap.

### 6.9  Favorit

Favorit disimpan di tabel `favorites` Supabase dengan RLS per pengguna, ditampilkan sebagai daftar kartu event, dengan aksi hapus semua dan empty state. Toggle hati tersedia pada kartu dan detail event. Perubahan langsung disinkronkan ke server, bukan disimpan di perangkat.

### 6.10  Profil

Konten: kartu profil bergradien (avatar inisial, nama, email, badge "Member Prioritas EventKuy"), tiga kartu statistik (Tiket Saya, Favorit, Poin), grup "Akun & Aktivitas" (Edit Informasi Profil, Riwayat Transaksi, Metode Pembayaran), grup "Mode Organizer" (Dashboard Organizer, Scan QR Check-in), grup "Bantuan" (Pusat Bantuan & FAQ, Hubungi CS), serta tombol "Keluar dari Akun" dengan dialog konfirmasi.

Menu "Dashboard Organizer" dan "Scan QR Check-in" membuka layar terkait. Kedua menu masih tampil untuk semua pengguna; backend menolak check-in dari akun non-organizer, tetapi UI belum menyembunyikan menu berdasarkan role. Sebagian menu lain belum berfungsi (onTap kosong).

### 6.11  Reusable Components

| Komponen | Kegunaan | Status |
|---|---|---|
| EventKuyLogo, EventKuyMark | Logo dan wordmark | Selesai |
| EventGridCard | Kartu poster grid dengan tombol favorit | Selesai |
| EventCard | Kartu horizontal untuk daftar | Selesai |
| HeroBanner | Banner event unggulan | Selesai |
| TicketItem | E-ticket boarding pass | Selesai |
| AppSearchBar | Input pencarian | Selesai |
| CategoryChip | Filter kategori | Selesai |
| SectionHeader | Judul section dan tautan | Selesai |
| PaymentOption | Radio-card pembayaran | Selesai |
| CustomButton | Tombol utama dengan varian loading/ikon | Selesai |
| EventImage | Gambar dengan cache dan fallback | Selesai |

### 6.12  State Management

| Provider | State yang Dikelola | Aksi |
|---|---|---|
| AuthProvider | User aktif, status login | `tryAutoLogin`, `login`, `register`, `logout` |
| EventProvider | Daftar event, query, kategori, loading | `loadEvents`, `setQuery`, `setCategory` |
| TicketProvider | Daftar tiket | `load`, `checkout`, `checkIn` |
| FavoriteProvider | Set ID favorit | `load`, `toggle` |

Provider dibuat di `main.dart` melalui `MultiProvider`. Widget membaca state dengan `context.watch` dan memanggil aksi dengan `context.read`.

### 6.13  Responsive Implementation

Seluruh layar utama memakai `LayoutBuilder` atau `ResponsiveLayout`, `ConstrainedContent`, serta perhitungan padding dan jumlah kolom dari `responsive.dart`. Pengujian otomatis memastikan tidak ada overflow pada 390, 768, 1080, dan 1400 px untuk komponen dan layar utama. Verifikasi visual tambahan dilakukan dengan build web release di headless Chrome pada 390x844, 768x1024, dan 1400x900.

### 6.14  UI Evidence Status

| Layar | Status | Bukti Otomatis | Screenshot |
|---|---|---|---|
| Splash | Selesai | widget_test | Belum ada |
| Login/Register | Selesai (Supabase Auth) | Verifikasi UI web | Screenshot login ada; register belum |
| Shell navigasi | Selesai | 3 ukuran | Terverifikasi headless Chrome |
| Beranda/Jelajahi | Selesai | 3 ukuran, semua tab | Terverifikasi headless Chrome |
| Detail Event | Selesai | 3 ukuran + regression bottom bar | Terverifikasi headless Chrome |
| Checkout | Selesai (pembayaran simulasi) | 3 ukuran | Belum ada |
| Tiket Saya | Selesai | 2 ukuran + PDF | Terverifikasi headless Chrome |
| Favorit/Profil | Selesai | 3 ukuran, semua tab | Terverifikasi headless Chrome |
| Organizer/Scan | Selesai; kamera pending | 2–3 ukuran + check-in manual | Terverifikasi headless Chrome |

**Gambar 6.** Tangkapan layar Login dan Register. Status: placeholder; screenshot login tersedia di lingkungan verifikasi, register belum.
**Gambar 7.** Tangkapan layar Beranda dan Jelajahi pada mobile dan desktop. Status: placeholder; screenshot beranda tersedia di lingkungan verifikasi.
**Gambar 8.** Tangkapan layar Detail Event dan Checkout. Status: placeholder; screenshot detail event tersedia, checkout belum.
**Gambar 9.** Tangkapan layar Tiket Saya dan Scan QR. Status: placeholder; screenshot tersedia di lingkungan verifikasi.
**Gambar 10.** Tangkapan layar Profil dan Dashboard Organizer. Status: placeholder; screenshot tersedia di lingkungan verifikasi.

---

## 7  QR Code, E-Ticket, and Check-in

**Status: Berjalan.** QR, PDF, dan check-in server sudah berfungsi; pemindaian kamera sudah diimplementasikan tetapi belum diuji di perangkat.

### 7.1  QR Code Generation

Kode tiket dibuat oleh database dengan format `EVK-` + 12 karakter acak dan disimpan unik di tabel `tickets`. QR dirender dengan `qr_flutter` dari kode tersebut, baik di layar tiket maupun di PDF. Validasi check-in dilakukan di server, bukan di klien.

### 7.2  Ticket Status Lifecycle

| Status | Tampilan | Perubahan |
|---|---|---|
| `pending` | Belum dipakai pada alur saat ini | Rencana untuk transaksi belum dibayar |
| `paid` | Badge "TIKET AKTIF" | Dibuat oleh RPC `checkout` setelah pembayaran simulasi |
| `checked_in` | Badge "SUDAH CHECK-IN" dan panel hijau | Diubah oleh RPC `check_in_ticket` |

### 7.3  Check-in Flow

Layar Scan QR menampilkan preview kamera `mobile_scanner`, tombol flash, bingkai scan, dan tombol **Masukkan Kode Manual** sebagai fallback. Alur check-in:

1. Organizer memindai QR atau mengetik kode tiket.
2. `TicketProvider.checkIn()` memanggil RPC `check_in_ticket`.
3. Server memverifikasi bahwa organizer adalah pemilik event, tiket berstatus `paid`, dan belum pernah check-in.
4. Dialog "Check-in Berhasil" menampilkan judul event dan kode tiket.
5. Kode yang sama ditolak dengan pesan "Tiket sudah pernah check-in"; akun non-organizer ditolak dengan pesan "Hanya organizer event...".

**Sinkronisasi otomatis ke perangkat attendee.** Setelah check-in berhasil di sisi organizer, `TicketProvider.startWatching()` membuat layar *Tiket Saya* ikut berubah tanpa reload manual:

- `EventKuyApi.watchTickets()` memakai Supabase Realtime (`from('tickets').stream(primaryKey: ['id']).eq('user_id', ...)`). Stream hanya dipakai sebagai pemicu; data lengkap diambil ulang lewat `fetchTickets()` agar judul event ikut terbawa.
- Perubahan diproses dengan debounce 300 ms, lalu tiket yang berubah dari `paid`/`pending` menjadi `checked_in` memunculkan SnackBar "Check-in berhasil — <kode>".
- `WidgetsBindingObserver` memuat ulang data saat aplikasi kembali aktif (resume), untuk kondisi koneksi terputus di latar belakang.
- Fallback: bila channel realtime gagal (mis. tabel `tickets` belum masuk publication `supabase_realtime`), provider otomatis beralih ke polling 5 detik. Aktivasi realtime ada di `supabase/realtime_tickets.sql`.
- RLS `tickets_select_own_or_organizer` tetap berlaku sehingga attendee hanya menerima baris tiketnya sendiri.

### 7.4  Camera Scanner

`mobile_scanner` sudah dipakai untuk preview dan pemindaian. Izin kamera ditambahkan di `AndroidManifest.xml` dan `Info.plist`. Pemindaian kamera belum diuji karena lingkungan pengembangan Windows/Linux tidak mendukung plugin ini; pengujian dilakukan lewat input kode manual di Chrome headless.

### 7.5  PDF Ticket

`TicketPdfService` membuat PDF A5 berisi judul event, status, nama pemilik, QR, dan kode tiket, memakai font Manrope. `Printing.sharePdf` membuka share sheet di mobile dan mengunduh file di web. Nama file mengikuti pola `EventKuy-<kode>.pdf`.

Verifikasi web: `EventKuy-EVK-984AADA30215.pdf` berhasil diunduh, ukuran 16.547 byte, header `%PDF-1.5`, dan QR terbaca.

### 7.6  Security Notes

- Kode tiket dibuat dan divalidasi di server.
- Check-in idempoten: tiket `checked_in` tidak dapat dipakai ulang.
- QR hanya memuat kode tiket, bukan data pribadi.
- RPC check-in memerlukan organizer pemilik event dan sesi login.

### 7.7  Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| QR-01 | E-ticket tampil dengan QR dan kode | QR dan TICKET ID tampil | Lulus (widget test 390 dan 1400) | Selesai |
| QR-02 | Check-in mengubah status tiket | Badge menjadi SUDAH CHECK-IN | Lulus (UI manual, `EVK-2EA0A2563B97`) | Selesai |
| QR-03 | Scan tanpa tiket aktif | Dialog "Tidak Ada Tiket Aktif" | Belum diuji otomatis | Belum diuji |
| QR-04 | Scan kamera asli | Kode terbaca dan divalidasi server | Kamera belum diuji | Tertunda |
| QR-05 | Unduh PDF | Berkas PDF tersimpan | Lulus (web, 16.547 byte) | Selesai |
| QR-06 | Check-in ganda | Ditolak server | Lulus (UI dan `verify-e2e.ps1`) | Selesai |

---

## 8  Organizer Dashboard and Reporting

**Status: Selesai (Supabase).** Dashboard dan statistik membaca event serta tiket nyata dari Supabase.

### 8.1  Dashboard

Layar "Dashboard Event Organizer" menampilkan logo, avatar, kartu event aktif (judul, tanggal, venue, badge status), tiga kartu statistik, dan daftar menu "Kelola Event".

Statistik dihitung dari tiket event milik organizer yang login:

```text
Tiket Terjual = jumlah tiket berstatus paid + checked_in
Total Peserta = jumlah tiket berstatus paid + checked_in
Check-in      = jumlah tiket berstatus checked_in
```

Event yang ditampilkan difilter dengan `event.organizerId == user.id`. Jika organizer belum punya event, dashboard menampilkan empty state, bukan event milik organizer lain.

Verifikasi 28 Oktober 2026 pada event Sound of Tomorrow: 3 tiket terjual,
3 peserta, dan 2 check-in saat dashboard diperiksa. Setelah check-in manual
`EVK-2EA0A2563B97`, jumlah check-in menjadi 3.

### 8.2  Manage Menu

| Menu | Aksi | Status |
|---|---|---|
| Detail Event | Membuka detail event | Selesai |
| Peserta | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Tiket | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Laporan | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Scan QR Check-in | Membuka layar scan | Selesai; kamera pending |

### 8.3  Reporting Plan

Laporan organizer dapat dikembangkan dari tabel `tickets` dan `transactions`: pendapatan, tingkat kehadiran, dan tren penjualan per event. Grafik dan ekspor laporan belum termasuk cakupan saat ini.

### 8.4  Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| ORG-01 | Dashboard tampil pada mobile dan desktop | Semua kartu statistik dan menu tampil, tanpa overflow | Lulus (390 dan 1400) | Selesai |
| ORG-02 | Buka detail event dari menu organizer | Detail event tampil | Lulus (widget test) | Selesai |
| ORG-03 | Statistik dari data transaksi nyata | Angka sesuai database | Lulus (3 peserta, 3 tiket, 2→3 check-in) | Selesai |
| ORG-04 | Organizer tanpa event | Empty state tampil | Lulus (widget test) | Selesai |

---

## 9  Testing, Optimization, and Deployment

Bagian ini memuat hasil pengujian aktual, batasannya, serta rencana optimasi dan rilis.

### 9.1  Testing Strategy and Traceability

Pengujian memakai tiga lapis: widget test deterministik dengan `MockApiService`,
verifikasi backend Supabase lewat script PowerShell, dan verifikasi UI web
dengan headless Chrome. Test case diturunkan dari requirement functional (FR)
dan dijalankan pada ukuran layar mobile, tablet, serta desktop.

Perintah verifikasi:

```bash
flutter analyze
flutter test
pwsh -File tool/verify-supabase.ps1
pwsh -File tool/verify-organizer.ps1
pwsh -File tool/verify-e2e.ps1
```

### 9.2  Actual Test Results

| Item | Hasil |
|---|---|
| Tanggal eksekusi | 28 Oktober 2026 |
| `flutter analyze` | No issues found (0 issue) |
| `flutter test` | 27 lulus, 0 gagal |
| Jumlah file test | 4 file: `ui_smoke_test.dart`, `event_grid_card_test.dart`, `widget_test.dart`, `ticket_pdf_test.dart` |
| Ukuran layar teruji | 390x844, 768x1024, 1080x800, 1366x620, 1400x900 |
| Pengujian perangkat fisik | Belum dilakukan |
| Pengujian API/backend | Lulus 3 script verifikasi Supabase |
| Pengujian unit perhitungan | Sebagian: PDF dan nama file; format rupiah/tanggal belum |

Rincian pengujian otomatis:

| Test ID | Kelompok | Jumlah Kasus | Hasil | Status |
|---|---|---|---|---|
| WT-01 | Detail Event lengkap + bottom bar (3 ukuran) | 3 | Lulus | Selesai |
| WT-02 | Tiket Saya + QR (2 ukuran) | 2 | Lulus | Selesai |
| WT-03 | Checkout lengkap (3 ukuran) | 3 | Lulus | Selesai |
| WT-04 | Scan Screen bebas overflow (3 ukuran) | 3 | Lulus | Selesai |
| WT-05 | Organizer Dashboard (2 ukuran + filter + empty state) | 4 | Lulus | Selesai |
| WT-06 | MainNavigation semua tab (3 ukuran) | 3 | Lulus | Selesai |
| WT-07 | EventGridCard bebas overflow (4 ukuran) | 4 | Lulus | Selesai |
| WT-08 | Boot aplikasi ke splash | 1 | Lulus | Selesai |
| WT-09 | Pembuatan PDF dan nama file | 3 | Lulus | Selesai |
| WT-10 | Check-in lewat kode manual di UI | 1 | Lulus | Selesai |

Contoh potongan test yang dipakai:

```dart
for (final size in const [Size(390, 844), Size(768, 1024), Size(1400, 900)]) {
  testWidgets('${size.width.toInt()}x${size.height.toInt()}', (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final events = await _loadedEventProvider(tester);
    await tester.pumpWidget(
      _wrap(child: EventDetailScreen(event: events.events.first), events: events),
    );
    await tester.pump();

    expect(find.text('Tentang Acara'), findsOneWidget);
    expect(find.text('Daftar & Beli Tiket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

**Gambar 11.** Tangkapan layar output `flutter test` (27/27 lulus). Status: placeholder; screenshot terminal aktual menyusul.

### 9.3  Regression Findings and Fixes

Selama pengembangan ditemukan beberapa masalah layout dan satu masalah konsistensi file. Semua sudah diperbaiki dan diverifikasi ulang:

| No | Temuan | Dampak | Perbaikan | Status |
|---|---|---|---|---|
| 1 | Kartu tiket memakai tinggi grid tetap 540 px | Overflow 21 px pada 390 dan 1400 | Tinggi adaptif `600 * textScaler` | Diperbaiki |
| 2 | Baris quick filter Jelajahi terlalu lebar di 390 | Overflow 9,8 px | Susunan kolom + chip dapat digulir pada layar sempit | Diperbaiki |
| 3 | Badge "Member Prioritas EventKuy" tidak fleksibel | Overflow 43 px pada 390 | Teks memakai `Flexible` dan ellipsis | Diperbaiki |
| 4 | File detail event sempat kembali ke versi lama | Konten detail tidak sesuai desain dan test gagal | File ditulis ulang sesuai desain | Diperbaiki |
| 5 | Baris total checkout berisiko overflow pada font uji | Overflow pada ukuran sempit | Baris total memakai `Wrap` | Diperbaiki |
| 6 | Bottom bar detail event memakai `Scaffold.bottomSheet` | Material 3 membatasi lebar 640 px; bar menutupi konten di tablet/desktop | Ganti ke `bottomNavigationBar`, full width, konten maksimal 860 px, padding body disesuaikan | Diperbaiki |
| 7 | Regression test belum memeriksa lebar bar | Bug lebar 640 px lolos dari pengujian | Tambah assertion `event-detail-buy-bar` pada 3 ukuran | Diperbaiki |

Catatan teknis: widget test Flutter memakai font Ahem yang membuat lebar/tinggi teks berbeda dari font asli, sehingga beberapa overflow hanya muncul di test. Perbaikan dilakukan agar layout tetap aman pada kedua kondisi. Debug print `EVENTKUY_DEBUG` juga sudah dihapus dari `lib/main.dart`.

### 9.4  Testing Not Yet Performed

| Area | Test yang Belum Ada | Rencana |
|---|---|---|
| Unit test | Format rupiah, tanggal, perhitungan total/diskon | Tambah test deterministik |
| API integration | Timeout, retry, dan kegagalan jaringan | Tambah test dengan server mock |
| Authentication | Registrasi baru, reset password via email | Uji manual di perangkat |
| Database | Edge case RLS tambahan | Perluas script verifikasi |
| Kamera | Izin, pemindaian QR, cahaya rendah | Uji di Chrome/Android |
| Perangkat | Instalasi APK, notch, gesture bar, Back, share sheet PDF | Fase rilis |
| Performa | Waktu muat, jumlah request, memori | Setelah uji perangkat |
| Checkout UI | Checkout langsung dari layar checkout ke Supabase | Uji E2E UI berikutnya |

### 9.5  Optimization and Robustness

- Gambar memakai `cached_network_image` dengan placeholder dan fallback otomatis.
- Grid event memakai rasio adaptif per breakpoint (0,60 / 0,82 / 0,90).
- Konten dibatasi maksimum 1200 px agar tetap nyaman di desktop.
- Area filter dan tab yang berpotensi sempit dibuat dapat digulir.
- Tinggi kartu tiket mengikuti skala teks pengguna.
- `flutter analyze` dipertahankan pada nol issue.
- Konfigurasi Supabase dimuat lewat `--dart-define-from-file`; file kredensial lokal di-ignore.
- Bottom bar detail event memakai `bottomNavigationBar` agar full width dan tidak menutupi konten.
- Debug print `EVENTKUY_DEBUG` sudah dihapus; jumlah pengujian aktif menjadi 27.

### 9.6  Build and Deployment

| Item | Status |
|---|---|
| Application ID | `com.eventkuy.app` |
| Label Android | `EventKuy` |
| Versi | 1.0.0+1 |
| Signing Android | Belum dikonfigurasi |
| Izin manifest | `INTERNET` dan `CAMERA` sudah ditambahkan; `NSCameraUsageDescription` ada di iOS |
| Build web release | Sukses 28 Oktober 2026 dengan `--dart-define-from-file=supabase.local.json` |
| Build APK/AAB | Belum dibangun |
| Emulator/perangkat Android | Belum diuji |
| Play Store | Belum dimulai |

Langkah rilis yang direncanakan: membuat signing key, membangun AAB,
menguji pada perangkat fisik (termasuk kamera dan share sheet PDF),
menyiapkan kebijakan privasi dan aset store, lalu mengunggah ke Play Console.

### 9.7  Risks and Mitigation

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Kamera belum diuji | Check-in QR belum terverifikasi di perangkat | Uji Chrome/Android dengan tiket nyata |
| Pembayaran simulasi | Tiket tidak benar-benar dibeli | Integrasi Midtrans sandbox |
| APK dan signing belum | Aplikasi belum dapat didistribusikan | Siapkan signing, build AAB, uji perangkat |
| Kredensial lokal | Kebocoran project Supabase | `supabase.local.json` di-ignore; hanya publishable key di aplikasi |
| Ketergantungan Supabase | Gangguan layanan atau perubahan skema | Simpan `schema.sql`/`seed.sql` dan backup database |
| Perubahan file tak terduga | Kode dapat kembali ke versi lama | Commit rutin dan review diff sebelum push |
| Unit test perhitungan terbatas | Kesalahan format/total tidak terdeteksi | Tambah unit test format rupiah dan total |
| Checkout UI belum diuji E2E | Alur checkout langsung dari UI belum terbukti | Uji checkout UI ke Supabase |

### 9.8  Final Project Evaluation

EventKuy sudah berjalan end-to-end di web dengan Supabase: autentikasi,
event, favorit, tiket, PDF, dashboard organizer, dan check-in manual. Checkout
dan voucher tervalidasi lewat RPC serta script backend; alur checkout langsung
dari layar checkout belum diuji E2E. Kualitas layout dijaga oleh 27 test, tiga
script verifikasi backend, dan verifikasi UI headless Chrome pada tiga ukuran
layar.

Aplikasi belum dapat dinyatakan selesai sebagai produk karena pemindaian
kamera belum diuji di perangkat, share sheet PDF Android/iOS belum diuji,
APK belum dibangun, dan pembayaran Midtrans masih simulasi.

Evaluasi mengikuti prinsip bukti: fitur yang dinyatakan selesai hanya fitur
yang memiliki kode dan hasil uji yang tercatat. Fitur yang masih simulasi
dinyatakan sebagai simulasi, bukan selesai penuh.

### 9.9  Final Application Overview

Artefak yang tersedia saat ini:

1. Repositori Flutter dengan layar utama, provider, model, dan service Supabase.
2. `supabase/schema.sql` dan `supabase/seed.sql` untuk database, RLS, RPC, dan data awal.
3. Tiga script verifikasi backend di `tool/`.
4. Dokumen desain dan kebutuhan: `DESIGN_SPEC.md`.
5. Laporan progress ini dan `docs/P0_CHECKLIST.md`.
6. Hasil `flutter analyze`, 27 test, dan build web release.

Artefak yang masih harus dilengkapi: screenshot aplikasi di repositori, hasil
build APK, bukti pengujian kamera/perangkat, dan integrasi pembayaran Midtrans.

---

## Checklist Bukti Implementasi Laporan

| Deliverable | Required Evidence | Status |
|---|---|---|
| System design | Architecture, use case, navigation, ERD | Sebagian (diagram teks; ERD Supabase terimplementasi) |
| Frontend implementation | Kode, screenshot, hasil test | Kode dan test tersedia; screenshot di lingkungan verifikasi, belum disalin ke repo |
| Authentication | Alur login/register/logout | Selesai (Supabase Auth; UI web terverifikasi) |
| Database | Skema dan hasil migrasi | Selesai (Supabase schema/seed) |
| REST API | Endpoint dan hasil uji | Selesai (SupabaseApi + 3 script verifikasi) |
| Payment | Integrasi Midtrans dan bukti transaksi | Simulasi; Midtrans pending |
| QR and check-in | QR, validasi kamera/server | QR/PDF/check-in server selesai; kamera pending |
| Security | Uji otorisasi dan kepemilikan data | Selesai (RLS + RPC ownership) |
| Testing | Test case dengan hasil aktual | 27/27 test + backend; device pending |
| Release | APK build dan uji perangkat | Build web sukses; APK pending |
| Documentation | Laporan progress, README, design spec | Tersedia |

---

## Daftar Referensi

Referensi resmi untuk verifikasi implementasi. Tanggal akses ditambahkan saat sumber benar-benar diperiksa.

[1] Flutter Team, "Flutter Documentation." https://docs.flutter.dev/
[2] Dart Team, "Dart Documentation." https://dart.dev/guides
[3] Flutter Team, "Testing Flutter apps." https://docs.flutter.dev/testing
[4] pub.dev, "provider — Flutter package." https://pub.dev/packages/provider
[5] pub.dev, "supabase_flutter — Flutter package." https://pub.dev/packages/supabase_flutter
[6] pub.dev, "qr_flutter — Flutter package." https://pub.dev/packages/qr_flutter
[7] pub.dev, "cached_network_image — Flutter package." https://pub.dev/packages/cached_network_image
[8] pub.dev, "pdf — Dart package." https://pub.dev/packages/pdf
[9] pub.dev, "printing — Flutter package." https://pub.dev/packages/printing
[10] pub.dev, "mobile_scanner — Flutter package." https://pub.dev/packages/mobile_scanner
[11] Supabase, "Supabase Documentation." https://supabase.com/docs
[12] Supabase, "Row Level Security." https://supabase.com/docs/guides/database/postgres/row-level-security
[13] PostgreSQL Global Development Group, "PostgreSQL Documentation." https://www.postgresql.org/docs/
[14] Midtrans, "Midtrans Documentation." https://docs.midtrans.com/
[15] Google, "Publish your app." https://support.google.com/googleplay/android-developer/answer/9859152

---

## Lampiran A — Struktur Proyek

```text
EventKuy/
  assets/
    fonts/            (Manrope 5 bobot, DM Sans 4 bobot)
    images/           (poster event)
  lib/                (43 file Dart, 9.158 baris)
    core/             (config, errors, responsive, theme)
    models/           (event, ticket, user, voucher, check_in_result)
    providers/        (auth, event, favorite, ticket)
    screens/          (auth, checkout, event, explore, favorite, home,
                       organizer, profile, scan, setup, splash, ticket,
                       main_navigation)
    services/         (api_service, supabase_api, mock_api_service,
                       ticket_pdf_service)
    widgets/          (komponen reusable)
  supabase/
    schema.sql        (tabel, RLS, trigger, RPC)
    seed.sql          (7 event + voucher)
  tool/
    verify-supabase.ps1
    verify-organizer.ps1
    verify-e2e.ps1
  test/
    ui_smoke_test.dart
    event_grid_card_test.dart
    widget_test.dart
    ticket_pdf_test.dart
  android/            (label EventKuy, applicationId com.eventkuy.app)
  ios/                (display name EventKuy, izin kamera)
  web/                (title dan manifest EventKuy)
  docs/
    P0_CHECKLIST.md
  DESIGN_SPEC.md
  README.md
  LAPORAN_PROGRESS.md
  supabase.local.example.json
  pubspec.yaml
```

---

## Lampiran B — Konsistensi Field Model, Database, dan JSON

Tabel ini menjadi acuan agar model Dart, JSON, dan kolom database tidak menyimpang.

| Entity | Kolom database/JSON | Atribut Dart saat ini | Tipe/Relasi |
|---|---|---|---|
| User | id, name, email | id, name, email | UUID string, string, string |
| Event | id, organizer_id, title, description, date, location, price, quota, image_url, category, tags, time_range | id, organizerId, title, description, date, location, price, quota, imageUrl, category, tags, timeRange | UUID, UUID, string, date, numeric, int |
| Ticket | id, code, event_id, user_id, status, created_at | id, code, eventId, eventTitle, status | UUID, string unik, string, enum status |
| Favorite | id, user_id, event_id | Set<String> pada provider | relasi user-event, unik per pasangan |
| Transaction | id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status, created_at | Belum ada model | numeric(12,2) |

Aturan konsistensi:

1. JSON memakai `snake_case`; Dart memakai `camelCase` dengan mapping eksplisit.
2. `tickets.code` unik dan dibuat database (`EVK-` + 12 karakter).
3. `tickets.status` hanya boleh `pending`, `paid`, atau `checked_in`.
4. Nilai uang disimpan sebagai `numeric(12,2)`.
5. Kepemilikan data diperiksa RLS dan RPC di server, bukan hanya di aplikasi.
6. `image_url` berisi path aset lokal; `EventImage` memakai fallback jaringan bila aset tidak tersedia.

---

## Lampiran C — Prosedur Reproduksi Verifikasi

```bash
# 1. Ambil dependensi
flutter pub get

# 2. Analisis statis
flutter analyze

# 3. Jalankan seluruh test
flutter test

# 4. Verifikasi backend Supabase
pwsh -File tool/verify-supabase.ps1
pwsh -File tool/verify-organizer.ps1
pwsh -File tool/verify-e2e.ps1

# 5. Build web dengan konfigurasi lokal
flutter build web --release --dart-define-from-file=supabase.local.json

# 6. Jalankan aplikasi pada Chrome
flutter run -d chrome --dart-define-from-file=supabase.local.json

# 7. Cek lingkungan pengembangan
flutter doctor
```

Hasil yang diharapkan pada kondisi saat ini:

```text
flutter analyze  -> No issues found
flutter test     -> 27 tes lulus
verify-supabase  -> lulus
verify-organizer -> lulus
verify-e2e       -> lulus
build web        -> sukses
```

Catatan: pengujian widget memakai font uji sehingga hasil visualnya tidak identik dengan aplikasi sebenarnya. Verifikasi visual dilakukan pada build web release di headless Chrome; pengujian kamera dan share sheet PDF masih memerlukan perangkat/Chrome interaktif.

---

## Rencana Pengembangan Berikutnya

| Fase | Lingkup | Status | Keluaran |
|---|---|---|---|
| A | Redesign UI, rebrand EventKuy, perbaikan layout, pengujian dasar | Selesai | Frontend responsif, 27 test lulus |
| B | Integrasi Supabase (skema, RLS, auth, event, favorit, checkout, tiket) | Selesai | Data nyata, 3 script verifikasi lulus |
| C | PDF e-ticket, dashboard organizer, check-in server | Selesai | PDF web, statistik nyata, check-in manual |
| D | Verifikasi UI web, regression bottom bar, dokumentasi | Selesai | Bukti headless Chrome, laporan tersinkron |
| E | Kamera QR dan share sheet PDF di perangkat | Berjalan | Uji Chrome/Android |
| F | Midtrans (checkout, webhook, status tiket) | Rencana | Pembayaran sandbox berfungsi |
| G | Build AAB, signing, uji perangkat, Play Store | Rencana | Rilis Android |

Estimasi progres keseluruhan bersifat indikatif: backend dan alur utama sudah
berjalan di web, sedangkan pembayaran riil, kamera, dan rilis Android belum
selesai.
