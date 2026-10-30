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
| Tanggal status | 22 Oktober 2026 |
| Platform utama | Android (Flutter), dengan layout responsif untuk tablet, desktop, dan web |
| Repositori | https://github.com/Acumalaka-ngod/-EventKuy-app.git (branch `main`) |
| Lingkungan verifikasi | Flutter 3.47.5, Dart 3.13.4, Windows 11, Chrome |
| Status keseluruhan | Frontend selesai dengan data mock; backend, pembayaran riil, dan rilis belum dimulai (estimasi progres indikatif 50 persen) |

---

## Petunjuk Penggunaan Laporan

Laporan ini disusun mengikuti pedoman penulisan laporan proyek aplikasi mobile: setiap bab memuat konteks, keputusan perancangan, status implementasi, dan bukti yang sudah atau belum tersedia. Laporan berfokus pada **progress**, bukan klaim bahwa seluruh aplikasi telah selesai.

Penyesuaian judul bab dilakukan agar sesuai dengan teknologi proyek: bagian CMS dan Firebase pada pedoman diganti dengan backend Laravel dan autentikasi Sanctum; bagian image capture diganti dengan QR/e-ticket; dan bagian laporan keuangan diganti dengan dashboard organizer. Struktur penomoran, gaya penulisan, tabel kebutuhan, tabel test case, dan aturan bukti tetap mengikuti pedoman.

Ketentuan status yang dipakai:

| Status | Arti |
|---|---|
| Selesai | Fitur berjalan dan dapat diverifikasi dari kode serta pengujian otomatis yang ada |
| Selesai (mock) | Alur UI lengkap, tetapi data, pembayaran, atau autentikasi masih disimulasikan |
| Berjalan | Sebagian sudah diimplementasikan, sebagian masih rencana |
| Rencana | Belum ada implementasi; baru berupa rancangan |
| Belum diuji | Implementasi ada, tetapi belum diuji pada lingkungan yang dimaksud |

Catatan bukti:

- Hasil pengujian yang dicantumkan pada Bab 9 berasal dari eksekusi nyata `flutter analyze` dan `flutter test` pada 22 Oktober 2026.
- Tangkapan layar aplikasi, hasil build APK, dan pengujian perangkat fisik **belum tersedia** dan ditandai sebagai placeholder. Placeholder tersebut wajib diganti dengan bukti aktual sebelum laporan akhir dikumpulkan.
- Seluruh diagram pada laporan ini masih berupa diagram teks sementara. Gambar final menyusul pada revisi laporan.
- Data event, pengguna, dan tiket pada aplikasi adalah data dummy, bukan data produksi.

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

EventKuy adalah aplikasi mobile untuk menemukan event (konser, seminar, workshop, dan olahraga), menyimpan event favorit, membeli tiket, serta menampilkan e-ticket ber-QR. Pengembangan saat ini berfokus pada frontend Flutter yang lengkap dan responsif, dengan data mock sebagai pengganti backend.

Capaian utama per 22 Oktober 2026:

1. Seluruh 13 tampilan utama telah diimplementasikan: splash, login, register, shell navigasi, beranda, jelajahi, tiket saya, favorit, profil, detail event, checkout, dialog sukses, dan bottom sheet.
2. Layout responsif tiga breakpoint berjalan: bottom bar mengambang pada mobile, rail ikon pada tablet, dan sidebar pada desktop.
3. Alur beli tiket end-to-end tersedia dalam mode simulasi: pilih event, checkout, voucher, metode pembayaran, dialog sukses, dan e-ticket ber-QR di menu Tiket Saya.
4. `flutter analyze` menghasilkan **No issues found**, dan `flutter test` lulus **21 dari 21 pengujian**.
5. Backend Laravel, MySQL, autentikasi riil, pembayaran Midtrans, kamera pemindai QR, unduh PDF, serta rilis Play Store belum diimplementasikan.

| Area | Status | Bukti |
|---|---|---|
| Perencanaan dan desain | Selesai (dokumen) | DESIGN_SPEC.md, laporan ini |
| Lingkungan pengembangan | Selesai | `flutter doctor`, `flutter analyze`, `flutter test` |
| Database dan backend | Rencana | Belum ada kode backend |
| Autentikasi | Selesai (mock) | Login/register/logout lokal |
| Integrasi REST API | Rencana | MockApiService, `http` belum dipakai |
| UI mobile | Selesai | 36 file Dart, 7.630 baris |
| QR, e-ticket, check-in | Berjalan | QR asli, check-in simulasi |
| Dashboard organizer | Berjalan | Statistik mock, menu sebagian |
| Pengujian | Berjalan | 21 widget test, tanpa unit/API/device test |
| Rilis | Rencana | APK belum dibangun |

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
3. Menyiapkan arsitektur yang siap diintegrasikan dengan backend Laravel, MySQL, dan Midtrans.
4. Menyediakan alur check-in tiket melalui QR untuk panitia event.
5. Mendokumentasikan progres secara terukur melalui pengujian otomatis dan bukti implementasi.

### 1.3  Functional Requirements

Kebutuhan fungsional diberi ID agar dapat ditelusuri ke layar, endpoint, dan test case.

| ID | Requirement | Bukti Penerimaan | Status Saat Ini |
|---|---|---|---|
| FR-01 | Registrasi, login, logout | Implementasi layar dan `AuthProvider` | Selesai (mock) |
| FR-02 | Melihat daftar event dan filter kategori/pencarian | Widget test Beranda/Jelajahi | Selesai (mock) |
| FR-03 | Melihat detail event lengkap | Widget test detail event | Selesai |
| FR-04 | Menyimpan dan menghapus event favorit | Persistensi SharedPreferences | Selesai |
| FR-05 | Checkout tiket dengan data pemesan | Widget test checkout | Selesai (mock) |
| FR-06 | Voucher promo dan perhitungan biaya | Implementasi logika voucher | Selesai (mock) |
| FR-07 | Memilih metode pembayaran | Widget test checkout | Selesai (mock) |
| FR-08 | E-ticket ber-QR | Widget test tiket | Selesai |
| FR-09 | Simulasi check-in tiket | Implementasi simulasi | Selesai (mock) |
| FR-10 | Filter tiket: Semua/Aktif/Selesai | Widget test tiket | Selesai |
| FR-11 | Profil pengguna dan logout | Widget test navigasi | Selesai (mock) |
| FR-12 | Dashboard organizer | Widget test organizer | Selesai (mock) |
| FR-13 | Notifikasi push | Belum ada | Rencana |
| FR-14 | Unduh e-ticket PDF | Snackbar simulasi | Rencana |
| FR-15 | Pembayaran riil (Midtrans) | Belum ada | Rencana |

### 1.4  Non-Functional Requirements

| Area | Target | Bukti atau Status |
|---|---|---|
| Keamanan | Tidak ada kredensial sensitif di repositori; token tidak ditampilkan di UI | Belum ada auth riil; password demo tidak divalidasi server |
| Usability | Validasi form jelas, state loading/empty/error tersedia | Sebagian; error jaringan belum ada karena mock |
| Responsif | Mobile, tablet, desktop tanpa overflow | Diuji otomatis pada 390, 768, 1080, 1400 px |
| Kinerja | Daftar event dan gambar tidak membebani perangkat | Gambar memakai `cached_network_image` dan aset lokal |
| Maintainability | Pemisahan layer UI, provider, model, service | Struktur `core`, `models`, `providers`, `screens`, `services`, `widgets` |
| Kompatibilitas | Android sebagai target utama; Flutter stabil | Flutter 3.47.5, Dart 3.13.4 |
| Kualitas kode | Tidak ada issue analyzer | `flutter analyze`: No issues found |
| Pengujian | Alur utama tercakup widget test | 21/21 lulus pada 22 Oktober 2026 |

### 1.5  Application Features and User Roles

| Peran | Fitur Utama | Akses | Status |
|---|---|---|---|
| Pengguna (pengunjung event) | Beranda, jelajahi, favorit, detail, checkout, tiket, profil | 5 tab utama | Selesai (mock) |
| Pengguna sebagai panitia/organizer | Dashboard organizer, kelola event, scan QR check-in | Menu di layar Profil | Berjalan (mock) |
| Administrator backend | Mengelola event, tiket, dan transaksi | Panel Laravel (rencana) | Rencana |

Hak akses saat ini baru berupa pemisahan layar, belum ada otorisasi server. Otorisasi riil akan diterapkan melalui token Sanctum dan policy kepemilikan data pada backend.

### 1.6  Technology Stack Overview

| Lapisan | Teknologi | Versi/Keterangan | Kegunaan |
|---|---|---|---|
| Mobile | Flutter | 3.47.5 (stable) | UI dan logika aplikasi |
| Bahasa | Dart | 3.13.4 | Implementasi |
| State | provider | ^6.1.5 | State management `ChangeNotifier` |
| Penyimpanan lokal | shared_preferences | ^2.5.3 | Sesi login mock dan favorit |
| QR | qr_flutter | ^4.1.0 | Render QR e-ticket |
| Gambar | cached_network_image | ^3.4.1 | Cache gambar jaringan |
| Format | intl | ^0.20.2 | Format tanggal Indonesia |
| Font | Manrope dan DM Sans | 9 berkas TTF | Tipografi aplikasi |
| HTTP | http | ^1.4.0 | Terpasang, belum dipakai (menunggu backend) |
| Kamera | mobile_scanner | ^7.0.1 | Terpasang, belum dipakai (scan masih simulasi) |
| Media | image_picker | ^1.1.2 | Terpasang, belum dipakai |
| Web | webview_flutter, url_launcher | ^4.13.0, ^6.3.2 | Terpasang, belum dipakai |
| Backend | Laravel, MySQL | Rencana | REST API, database relasional |
| Pembayaran | Midtrans | Rencana | Payment gateway |
| Distribusi | Play Store | Rencana | Rilis Android |

Catatan: paket `http`, `mobile_scanner`, `image_picker`, `webview_flutter`, dan `url_launcher` sudah ada di `pubspec.yaml` sebagai persiapan fase berikutnya, tetapi belum diimpor oleh kode aplikasi. Pemeriksaan impor pada 22 Oktober 2026 menunjukkan `package:http` hanya muncul di komentar rencana.

### 1.7  High-Level System Architecture

Arsitektur saat ini (frontend dengan data mock):

```text
Splash / Auth screens
        |
MainNavigation (5 tab)
        |
Screens  ->  Providers (ChangeNotifier)  ->  MockApiService (data in-memory)
        |            |                              |
        |            +--> SharedPreferences          +--> assets/images/*.jpg
        |                 (sesi, favorit)
        +--> Widgets bersama (EventCard, TicketItem, AppSearchBar, dll.)
```

Arsitektur target setelah backend tersedia:

```text
Flutter UI  ->  Providers  ->  ApiService (package:http)  ->  Laravel REST API
                    |                                          |
                    |                                          +--> MySQL
                    +--> SharedPreferences / secure storage    +--> Midtrans
```

Prinsip yang sudah diterapkan: widget tidak memanggil sumber data secara langsung; provider menjadi perantara; model memiliki `fromJson`/`toJson` untuk memudahkan integrasi API; konfigurasi URL dan timeout dipusatkan di `lib/core/config.dart`.

**Gambar 1.** Arsitektur sistem EventKuy saat ini dan target. Status: placeholder diagram teks; gambar final menyusul.

### 1.8  Application Use Case Diagram

Aktor dan use case utama:

| Aktor | Use Case |
|---|---|
| Pengguna | Registrasi, login, logout, melihat beranda, mencari event, memfilter kategori, melihat detail, menyimpan favorit, checkout, memakai voucher, memilih pembayaran, melihat e-ticket, simulasi check-in, mengubah profil (rencana) |
| Panitia/Organizer | Membuka dashboard organizer, melihat statistik event, membuka detail event, scan QR check-in |
| Administrator (rencana) | Mengelola master event, tiket, dan transaksi melalui backend |

Prasyarat: use case pembelian dan tiket memerlukan status login (masih berupa demo lokal). Use case check-in memerlukan tiket berstatus `paid`.

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
| 2 | Login | Selesai (mock) | Kode implementasi |
| 3 | Register | Selesai (mock) | Kode implementasi |
| 4 | Shell navigasi responsif | Selesai | Widget test 3 breakpoint |
| 5 | Beranda | Selesai (mock) | Widget test navigasi |
| 6 | Jelajahi | Selesai (mock) | Widget test navigasi |
| 7 | Tiket Saya | Selesai | Widget test 2 ukuran |
| 8 | Favorit | Selesai | Widget test navigasi |
| 9 | Profil | Selesai | Widget test navigasi |
| 10 | Detail Event | Selesai | Widget test 3 ukuran |
| 11 | Checkout | Selesai (mock) | Widget test 3 ukuran |
| 12 | Dialog sukses pembayaran | Selesai (mock) | Kode dan alur |
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

Database belum diimplementasikan. Rancangan awal entitas diturunkan dari model dan layar yang sudah ada, dan masih dapat berubah pada fase backend:

| Entitas | Atribut Inti | Keterangan |
|---|---|---|
| users | id, name, email, password, role, created_at | Autentikasi; `role` untuk pengguna/organizer |
| events | id, title, description, date, location, price, quota, image_url, category, tags, time_range | Mirror model `Event` |
| tickets | id, code, event_id, user_id, status, created_at | Status `pending`, `paid`, `checked_in` |
| transactions | id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status, created_at | Rencana checkout |
| favorites | user_id, event_id | Rencana sinkronisasi favorit |
| vouchers | code, discount, active_from, active_to, quota | Rencana voucher server-side |

Relasi utama: satu user memiliki banyak ticket, transaction, dan favorite; satu event memiliki banyak ticket dan transaction; satu transaction menghasilkan satu ticket; satu ticket terkait satu event.

Catatan konsistensi: model Flutter saat ini memakai `event_id` dan `event_title` pada `Ticket`, serta `image_url` dan `time_range` pada `Event`. Penamaan kolom database dan JSON harus diselaraskan sebelum backend dibuat (lihat Lampiran B).

**Gambar 5.** Rencana ERD EventKuy. Status: rancangan, belum diimplementasikan.

### 1.12  REST API Endpoint Specification

Belum ada endpoint yang berjalan. Rancangan kontrak API untuk fase backend:

| Method | Endpoint (rencana) | Kegunaan | Status |
|---|---|---|---|
| POST | `/api/register` | Registrasi pengguna | Rencana |
| POST | `/api/login` | Login, menerbitkan token Sanctum | Rencana |
| POST | `/api/logout` | Mencabut token | Rencana |
| GET | `/api/events` | Daftar event, mendukung filter kategori, pencarian, kota | Rencana |
| GET | `/api/events/{id}` | Detail event | Rencana |
| GET | `/api/favorites` | Daftar favorit pengguna | Rencana |
| POST | `/api/favorites/{eventId}` | Menambah favorit | Rencana |
| DELETE | `/api/favorites/{eventId}` | Menghapus favorit | Rencana |
| POST | `/api/checkout` | Membuat transaksi dan tiket | Rencana |
| POST | `/api/payments/midtrans` | Membuat token pembayaran | Rencana |
| POST | `/api/payments/notification` | Webhook status pembayaran | Rencana |
| GET | `/api/tickets` | Tiket milik pengguna | Rencana |
| POST | `/api/tickets/{code}/check-in` | Validasi dan check-in tiket | Rencana |
| GET | `/api/organizer/events` | Event milik organizer | Rencana |

Header yang direncanakan: `Authorization: Bearer <token>`, `Accept: application/json`, dan `Content-Type: application/json` untuk permintaan bertubuh JSON. Semua endpoint privat wajib memverifikasi kepemilikan data di server, bukan hanya di aplikasi.

---

## 2  Development Environment Setup

Bagian ini mencatat lingkungan pengembangan yang benar-benar dipakai dan hasil verifikasinya.

### 2.1  Creating the EventKuy Flutter Project

Proyek dibuat dengan Flutter CLI. Nama paket internal tetap `ajangin` dan `applicationId` tetap `com.ajangin.app`; nama brand yang tampil di UI, Android, iOS, dan web adalah **EventKuy**.

```bash
flutter create ajangin
cd ajangin
flutter pub get
flutter run -d chrome
```

Informasi versi aplikasi: `version: 1.0.0+1` pada `pubspec.yaml`.

### 2.2  Installing Required Flutter Packages

Dependensi dipasang sesuai kebutuhan. Status pemakaian diperiksa langsung dari impor kode:

| Paket | Versi | Status | Kegunaan |
|---|---|---|---|
| provider | ^6.1.5 | Dipakai | State management |
| shared_preferences | ^2.5.3 | Dipakai | Sesi demo dan favorit |
| qr_flutter | ^4.1.0 | Dipakai | QR e-ticket |
| intl | ^0.20.2 | Dipakai | Format tanggal |
| cached_network_image | ^3.4.1 | Dipakai | Cache gambar |
| http | ^1.4.0 | Belum dipakai | Persiapan API Laravel |
| mobile_scanner | ^7.0.1 | Belum dipakai | Persiapkan kamera QR |
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
    mock_api_service.dart
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

Pemisahan ini memudahkan penggantian `MockApiService` dengan `ApiService` tanpa mengubah widget.

### 2.4  Configuring Environment Variables

Konfigurasi global berada di `lib/core/config.dart`:

```dart
class AppConfig {
  static const String appName = 'EventKuy';
  static const String applicationId = 'com.ajangin.app';
  static const String apiBaseUrl = 'https://api.eventkuy.id/api';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const String midtransClientKey = '';
  static const bool midtransIsProduction = false;
}
```

Catatan:

- `apiBaseUrl` masih placeholder dan belum dipanggil oleh kode mana pun.
- `midtransClientKey` masih kosong; integrasi pembayaran belum dimulai.
- Tidak ada kredensial rahasia yang disimpan di repositori. Untuk fase produksi, nilai sensitif sebaiknya dipasok melalui `--dart-define` atau mekanisme build, bukan ditulis langsung di sumber.

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
| applicationId | `com.ajangin.app` | Dipertahankan dari proyek awal |
| compileSdk/minSdk/targetSdk | Mengikuti `flutter.*` bawaan | Selesai |
| Izin INTERNET Android | Hanya ada di manifest debug | **Perlu ditambahkan ke manifest utama sebelum rilis** |
| Izin kamera Android | Belum dideklarasikan | Rencana (fase scanner) |
| iOS display name | `EventKuy` | Selesai |
| iOS camera/photo usage description | Belum ada | Rencana (fase scanner) |

### 2.7  Version Control Setup

| Item | Nilai |
|---|---|
| Repositori | `https://github.com/Acumalaka-ngod/-EventKuy-app.git` |
| Branch aktif | `main` |
| Commit terakhir | `b503219` — mengabaikan artefak build Gradle |
| Perubahan belum di-commit | 39 berkas pada 22 Oktober 2026 |
| Artefak build | Diabaikan melalui `.gitignore` |

Perubahan redesign dan perbaikan terbaru belum di-commit. Commit dan push perlu dilakukan setelah verifikasi visual oleh pemilik proyek.

### 2.8  Testing Environment

| Perintah | Hasil |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 21/21 lulus |
| `flutter doctor` | Satu peringatan (Visual Studio tidak terpasang) |
| `flutter run -d chrome` | Tersedia sebagai target pengembangan |

Ukuran layar yang diuji otomatis: 390x844 (HP), 768x1024 (tablet), 1080x800 (laptop kecil), 1366x620 (jendela Chrome pendek), 1400x900 (desktop).

---

## 3  Database and Backend Implementation

**Status: Rencana (belum ada implementasi).** Bab ini mencatat rancangan agar laporan tetap dapat ditelusuri ke fase berikutnya. Tidak ada bukti implementasi database karena backend belum dimulai.

### 3.1  Designing the EventKuy Database

Rancangan memakai MySQL dengan primary key auto-increment untuk `users` dan `events`, serta kode tiket unik untuk `tickets`. Nilai uang disimpan sebagai integer rupiah agar tidak ada pembulatan pecahan. Tanggal event disimpan sebagai `datetime`; status tiket dibatasi pada `pending`, `paid`, dan `checked_in`.

Alasan pemilihan: kebutuhan relasional (user, event, tiket, transaksi) lebih mudah dijaga dengan foreign key dan constraint dibanding penyimpanan dokumen.

### 3.2  Planned Tables

| Tabel | Kolom Rencana | Constraint |
|---|---|---|
| users | id, name, email, password, role, created_at | email unik, password hash |
| events | id, title, description, date, location, price, quota, image_url, category, tags, time_range, organizer_id | harga dan kuota >= 0 |
| tickets | id, code, event_id, user_id, status, checked_in_at, created_at | code unik, FK event/user |
| transactions | id, order_id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status, created_at | FK user/event/ticket |
| favorites | user_id, event_id, created_at | unik per pasangan |
| vouchers | code, discount, active_from, active_to, quota | code unik |

Model Flutter yang sudah ada (`Event`, `Ticket`, `AppUser`) menjadi acuan awal. Detail konsistensi field ada pada Lampiran B.

### 3.3  Relationships and Constraints

- `tickets.event_id` mengacu ke `events.id`; `tickets.user_id` mengacu ke `users.id`.
- `transactions.ticket_id` mengacu ke `tickets.id`; satu transaksi menghasilkan satu tiket.
- `favorites` memakai kunci gabungan `(user_id, event_id)`.
- Harga, biaya layanan, dan diskon tidak boleh negatif. Total dihitung di server dan diverifikasi ulang sebelum pembayaran.
- Status tiket hanya boleh berubah dari `pending` ke `paid` ke `checked_in`; perubahan mundur ditolak.

### 3.4  Authorization and Data Ownership Plan

Autentikasi rencana memakai Laravel Sanctum. Setiap endpoint privat memverifikasi token dan kepemilikan data:

- Pengguna hanya dapat membaca tiket, transaksi, dan favorit miliknya.
- Organizer hanya dapat mengelola event miliknya.
- Check-in tiket divalidasi oleh server; aplikasi panitia tidak boleh mengubah status tiket secara lokal.
- Kunci rahasia pembayaran (Midtrans server key) hanya disimpan di server.

### 3.5  Seed Data Plan

Data awal akan memakai 7 event dummy yang saat ini ada di `MockApiService` (Sound of Tomorrow, We The Fest 2025, Photography Workshop, Future of Technology, Jakarta Running Festival, UI/UX Design Workshop, Digital Marketing Summit) dengan gambar aset lokal. Seed harus idempoten agar aman dijalankan ulang.

### 3.6  Testing Plan

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| DB-01 | Migrasi dan seed dijalankan pada database kosong | Semua tabel terbentuk, 7 event tersedia | Belum dijalankan | Rencana |
| DB-02 | Insert tiket dengan event_id tidak valid | Ditolak foreign key | Belum dijalankan | Rencana |
| DB-03 | Pengguna A membaca tiket pengguna B | Ditolak atau kosong | Belum dijalankan | Rencana |
| DB-04 | Check-in ganda pada tiket yang sama | Ditolak | Belum dijalankan | Rencana |

Bukti implementasi yang harus disertakan setelah backend dibuat: skema aktual, hasil migrasi, dan log pengujian.

---

## 4  Authentication Implementation

**Status: Selesai (mock).** Autentikasi riil belum ada; alur UI dan penyimpanan sesi lokal sudah berjalan.

### 4.1  Current Authentication Flow

```text
Splash (2 detik)
  -> AuthProvider.tryAutoLogin()
     -> SharedPreferences berisi user_email?
        -> ya: MainNavigation
        -> tidak: LoginScreen
LoginScreen -> loginDummy(name, email) -> simpan user_email, user_name -> MainNavigation
Logout -> hapus SharedPreferences -> LoginScreen
```

### 4.2  Login Screen

Layar login mencakup field nama lengkap, email, password dengan toggle visibilitas, checkbox "Ingat saya", tautan "Lupa Password?", tombol "Masuk Sekarang", tombol Google/Apple (belum berfungsi), dan tautan ke registrasi. Nilai awal form adalah data demo:

- Nama: `Andi Pratama`
- Email: `andi@eventkuy.id`
- Password: `eventkuy123`

Validasi saat ini hanya memeriksa field wajib tidak kosong. Password tidak diverifikasi karena belum ada server.

### 4.3  Register Screen

Form registrasi mencakup nama, email, password, konfirmasi password, dan persetujuan syarat & ketentuan. Validasi yang berjalan:

1. Semua field wajib harus terisi.
2. Konfirmasi password harus sama.
3. Checkbox syarat & ketentuan harus dicentang.

Setelah sukses (simulasi 800 ms), muncul snackbar "Akun berhasil dibuat. Silakan masuk." dan layar kembali ke login. Akun tidak benar-benar tersimpan.

### 4.4  AuthProvider Implementation

```dart
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      _user = AppUser(
        id: 1,
        name: prefs.getString('user_name') ?? 'Pengguna',
        email: email,
      );
      notifyListeners();
    }
  }
}
```

Kelemahan yang diakui:

- Email dan nama disimpan sebagai plaintext di SharedPreferences.
- Tidak ada token, tidak ada validasi server, dan tidak ada masa berlaku sesi.
- Belum ada proteksi rute per layar; layar privat dapat dibuka jika navigasi dipanggil langsung.

### 4.5  Planned Integration with Laravel Sanctum

Rencana: `POST /api/login` mengembalikan token; token disimpan pada penyimpanan aman; `ApiService` menyisipkan header `Authorization`; `401` memicu logout dan kembali ke login. Penyimpanan token idealnya memakai `flutter_secure_storage` (belum ditambahkan).

### 4.6  Authentication Test Plan

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| AUTH-01 | Login dengan data lengkap | Masuk ke MainNavigation | Belum diuji otomatis | Belum diuji |
| AUTH-02 | Login dengan field kosong | Pesan validasi, tidak berpindah layar | Belum diuji otomatis | Belum diuji |
| AUTH-03 | Registrasi dengan konfirmasi password berbeda | Pesan kesalahan | Belum diuji otomatis | Belum diuji |
| AUTH-04 | Sesi dipulihkan setelah aplikasi ditutup | Langsung ke beranda | Belum diuji pada perangkat | Belum diuji |
| AUTH-05 | Logout lalu membuka layar privat | Dialihkan ke login | Belum diuji | Rencana |
| AUTH-06 | Login dengan akun server | Token tersimpan dan dipakai API | Belum ada backend | Rencana |

Bukti pengujian otomatis untuk autentikasi baru mencakup boot aplikasi ke splash (`widget_test.dart`). Pengujian login/registrasi masih manual.

---

## 5  REST API Integration

**Status: Rencana.** Belum ada permintaan HTTP ke server. Seluruh data berasal dari `MockApiService`.

### 5.1  Mock API Service

`lib/services/mock_api_service.dart` menyediakan 7 event dengan latensi buatan 600 ms dan gambar dari `assets/images/`. Jika aset lokal tidak tersedia, `EventImage` memakai fallback `https://picsum.photos/seed/eventkuy{id}/600/400`.

Data event mencakup kategori Konser, Seminar, Workshop, dan Olahraga; harga Rp 150.000–Rp 750.000; kuota 200–10.000; serta lokasi di Jakarta dan Bandung. Data ini akan dipindahkan ke seed backend.

### 5.2  Planned API Service

Rencana file `lib/services/api_service.dart`:

```dart
class ApiService {
  Future<List<Event>> fetchEvents() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/events'),
    ).timeout(AppConfig.apiTimeout);
    // decode, validasi status, mapping fromJson
  }
}
```

Tanggung jawab service: menyusun URL, header, timeout, decoding JSON, dan menerjemahkan status HTTP menjadi error terstruktur. Provider tetap menjadi satu-satunya pihak yang memanggil service.

### 5.3  JSON Serialization

Model yang sudah siap:

```dart
factory Event.fromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as int,
  title: json['title'] as String,
  date: DateTime.parse(json['date'] as String),
  price: json['price'] as int,
  imageUrl: json['image_url'] as String? ?? '',
  timeRange: json['time_range'] as String? ?? '',
);

factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
  code: json['code'] as String,
  eventId: json['event_id'] as int,
  eventTitle: json['event_title'] as String? ?? '',
  status: json['status'] as String? ?? 'pending',
);
```

JSON memakai `snake_case`, Dart memakai `camelCase`. Mapping eksplisit menjaga konsistensi dan memudahkan validasi tipe.

### 5.4  Endpoint Mapping to Screens

| Layar | Endpoint Rencana | Data |
|---|---|---|
| Beranda/Jelajahi | `GET /events` | Daftar event, filter kategori/kota |
| Detail | `GET /events/{id}` | Detail event |
| Favorit | `GET/POST/DELETE /favorites` | Sinkronisasi favorit |
| Checkout | `POST /checkout` | Membuat transaksi dan tiket |
| Checkout | `POST /payments/midtrans` | Token pembayaran |
| Tiket Saya | `GET /tickets` | Tiket pengguna |
| Scan | `POST /tickets/{code}/check-in` | Validasi check-in |
| Organizer | `GET /organizer/events` | Statistik dan event |

### 5.5  Error Handling Plan

Status yang perlu ditangani: 200/201 sukses, 204 tanpa isi, 400 validasi, 401 token tidak sah, 403 akses ditolak, 404 resource tidak ditemukan, 409 konflik, dan 5xx kegagalan server. UI menampilkan pesan singkat yang dapat ditindaklanjuti; detail teknis hanya masuk log pengembangan tanpa token atau data pribadi.

### 5.6  Current Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| API-01 | GET daftar event | 200, data ter-parse | Belum ada backend | Rencana |
| API-02 | Checkout dengan voucher valid | Total berkurang Rp 25.000 | Baru diuji di UI mock | Belum diuji |
| API-03 | Checkout dengan voucher salah | Pesan merah, total tetap | Baru diuji di UI mock | Belum diuji |
| API-04 | 401 saat token kedaluwarsa | Logout dan login ulang | Belum ada backend | Rencana |
| API-05 | Timeout jaringan | Pesan error dan opsi coba lagi | Belum ada backend | Rencana |

Tidak ada bukti pengujian API karena service HTTP belum terhubung ke server.

---

## 6  EventKuy Mobile UI Development

**Status: Selesai (frontend dengan data mock).** Seluruh layar utama sudah diimplementasikan dan diuji bebas overflow pada beberapa ukuran layar.

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

Konten: hero image dengan tombol kembali, bagikan, dan favorit; indikator "1 / 4 Foto"; chip kategori dan rating "4.9 (320 ulasan)"; judul; kartu tanggal/waktu; kartu lokasi berisi alamat lengkap; kartu organizer dengan tombol "Ikuti"; section "Tentang Acara"; tagar; serta bottom bar sticky berisi "Harga Tiket" dan tombol "Daftar & Beli Tiket".

Tombol bagikan baru menampilkan snackbar; native share belum diimplementasikan. Tombol organizer menampilkan snackbar konfirmasi mengikuti.

### 6.7  Checkout

Konten: step indicator (Pilih, Bayar, E-Tiket), kartu ringkasan event, form informasi pemesan (nama, email, nomor WhatsApp), tiga metode pembayaran (GoPay, Virtual Account, Kartu Kredit/Debit), voucher, rincian biaya (harga tiket, biaya layanan Rp 2.500, diskon), total, dan tombol "Bayar Sekarang".

Perilaku simulasi:

- Voucher valid: `EVENTKUY` dan `DISKON10`, diskon Rp 25.000.
- Voucher salah menampilkan pesan merah.
- Tombol bayar menampilkan loading, membuat tiket status `paid` melalui `TicketProvider.buyDummy`, lalu menampilkan dialog sukses dengan TICKET ID dan tombol "Lihat Tiket Saya".
- Layout desktop memakai dua kolom (form di kiri, ringkasan total di kanan); mobile satu kolom.
- Tombol bayar tidak memanggil payment gateway.

### 6.8  Tiket Saya

Konten: judul "Tiket & Pass Saya", tab Semua/Aktif/Selesai dengan jumlah, kartu e-ticket bergaya boarding pass (header gradien, badge status, judul event, jadwal, perforasi, QR, TICKET ID, tombol simulasi check-in, pemilik tiket, unduh PDF), serta empty state.

QR dihasilkan dari kode tiket (format `EVK-...`) dan dapat dipindai secara teknis. Tombol check-in mengubah status menjadi `checked_in` dan badge menjadi "SUDAH CHECK-IN". Tombol "Unduh PDF" masih berupa snackbar simulasi.

Grid tiket memakai 1/2/3 kolom dengan tinggi adaptif terhadap skala teks agar tidak overlap.

### 6.9  Favorit

Favorit disimpan di SharedPreferences (`favorite_event_ids`), ditampilkan sebagai daftar kartu event, dengan aksi hapus semua dan empty state. Toggle hati tersedia pada kartu dan detail event.

### 6.10  Profil

Konten: kartu profil bergradien (avatar inisial, nama, email, badge "Member Prioritas EventKuy"), tiga kartu statistik (Tiket Saya, Favorit, Poin), grup "Akun & Aktivitas" (Edit Informasi Profil, Riwayat Transaksi, Metode Pembayaran), grup "Mode Organizer" (Dashboard Organizer, Scan QR Check-in), grup "Bantuan" (Pusat Bantuan & FAQ, Hubungi CS), serta tombol "Keluar dari Akun" dengan dialog konfirmasi.

Menu "Dashboard Organizer" dan "Scan QR Check-in" pada grup "Mode Organizer" membuka layar terkait. Sebagian menu lain belum berfungsi (onTap kosong).

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
| AuthProvider | User aktif, status login | `tryAutoLogin`, `loginDummy`, `logout` |
| EventProvider | Daftar event, query, kategori, loading | `loadEvents`, `setQuery`, `setCategory` |
| TicketProvider | Daftar tiket | `buyDummy`, `checkIn` |
| FavoriteProvider | Set ID favorit | `load`, `toggle` |

Provider dibuat di `main.dart` melalui `MultiProvider`. Widget membaca state dengan `context.watch` dan memanggil aksi dengan `context.read`.

### 6.13  Responsive Implementation

Seluruh layar utama memakai `LayoutBuilder` atau `ResponsiveLayout`, `ConstrainedContent`, serta perhitungan padding dan jumlah kolom dari `responsive.dart`. Pengujian otomatis memastikan tidak ada overflow pada 390, 768, 1080, dan 1400 px untuk komponen dan layar utama.

### 6.14  UI Evidence Status

| Layar | Status | Bukti Otomatis | Screenshot |
|---|---|---|---|
| Splash | Selesai | widget_test | Placeholder |
| Login/Register | Selesai (mock) | Belum ada test otomatis | Placeholder |
| Shell navigasi | Selesai | 3 ukuran | Placeholder |
| Beranda/Jelajahi | Selesai | 3 ukuran, semua tab | Placeholder |
| Detail Event | Selesai | 3 ukuran | Placeholder |
| Checkout | Selesai (mock) | 3 ukuran | Placeholder |
| Tiket Saya | Selesai | 2 ukuran | Placeholder |
| Favorit/Profil | Selesai | 3 ukuran, semua tab | Placeholder |
| Organizer/Scan | Berjalan (mock) | 2–3 ukuran | Placeholder |

**Gambar 6.** Tangkapan layar Login dan Register. Status: placeholder; screenshot aktual menyusul.
**Gambar 7.** Tangkapan layar Beranda dan Jelajahi pada mobile dan desktop. Status: placeholder.
**Gambar 8.** Tangkapan layar Detail Event dan Checkout. Status: placeholder.
**Gambar 9.** Tangkapan layar Tiket Saya dan Scan QR. Status: placeholder.
**Gambar 10.** Tangkapan layar Profil dan Dashboard Organizer. Status: placeholder.

---

## 7  QR Code, E-Ticket, and Check-in

**Status: Berjalan.** QR asli dan status tiket sudah berfungsi; pemindaian kamera dan validasi server belum.

### 7.1  QR Code Generation

QR dibuat dengan `qr_flutter` dari kode tiket. Kode dibentuk oleh `TicketProvider.buyDummy`:

```dart
final code = 'EVK-${event.id}${DateTime.now().millisecondsSinceEpoch % 100000}';
```

QR dapat dipindai oleh aplikasi pembaca QR biasa. Namun validasi tiket masih lokal di aplikasi, sehingga kode belum ditandatangani secara kriptografis.

### 7.2  Ticket Status Lifecycle

| Status | Tampilan | Perubahan |
|---|---|---|
| `pending` | Belum dipakai pada alur saat ini | Rencana untuk transaksi belum dibayar |
| `paid` | Badge "TIKET AKTIF" | Dibuat setelah checkout simulasi |
| `checked_in` | Badge "SUDAH CHECK-IN" dan panel hijau | Setelah tombol simulasi check-in |

### 7.3  Simulated Check-in

Layar Scan QR menampilkan latar gelap, bingkai scan dengan animasi garis, tombol flash, dan kartu event. Ketuk bingkai untuk simulasi:

1. Provider mencari tiket pertama yang belum check-in.
2. Status tiket diubah menjadi `checked_in`.
3. Dialog "Check-in Berhasil" menampilkan judul event dan kode tiket.
4. Jika tidak ada tiket aktif, muncul dialog "Tidak Ada Tiket Aktif".

### 7.4  Camera Scanner Plan

`mobile_scanner` sudah terpasang tetapi belum dipakai. Langkah berikutnya: menambahkan izin kamera Android/iOS, mengganti bingkai simulasi dengan `MobileScanner`, memvalidasi kode ke server, dan mencatat riwayat scan. Dokumen ini tidak mengklaim kamera sudah berfungsi.

### 7.5  PDF Ticket Plan

Tombol "Unduh PDF" saat ini hanya menampilkan snackbar simulasi. Rencana: membuat PDF dari data tiket dan QR, menyimpannya ke penyimpanan perangkat, lalu membagikan berkas melalui `share_plus` (belum terpasang).

### 7.6  Security Notes

- Kode tiket harus dibuat dan divalidasi di server, bukan hanya di klien.
- Check-in perlu idempotensi: tiket yang sudah dipakai tidak boleh dipakai ulang.
- QR tidak boleh memuat data pribadi selain kode tiket.
- Endpoint check-in memerlukan otorisasi organizer.

### 7.7  Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| QR-01 | E-ticket tampil dengan QR dan kode | QR dan TICKET ID tampil | Lulus (widget test 390 dan 1400) | Selesai |
| QR-02 | Check-in mengubah status tiket | Badge menjadi SUDAH CHECK-IN | Belum diuji otomatis | Belum diuji |
| QR-03 | Scan tanpa tiket aktif | Dialog "Tidak Ada Tiket Aktif" | Belum diuji otomatis | Belum diuji |
| QR-04 | Scan kamera asli | Kode terbaca dan divalidasi server | Belum ada kamera/server | Rencana |
| QR-05 | Unduh PDF | Berkas PDF tersimpan | Masih snackbar simulasi | Rencana |

---

## 8  Organizer Dashboard and Reporting

**Status: Berjalan (mock).** Dashboard dan navigasi tersedia; statistik masih dihitung dari kuota event dengan pengali simulasi.

### 8.1  Dashboard

Layar "Dashboard Event Organizer" menampilkan logo, avatar, kartu event aktif (judul, tanggal, venue, badge "Sedang Berlangsung"), tiga kartu statistik, dan daftar menu "Kelola Event".

Statistik saat ini:

```text
Tiket Terjual = event.quota
Total Peserta = round(event.quota * 1.083)
Check-in      = round(event.quota * 0.947)
```

Angka tersebut adalah simulasi tampilan, bukan agregasi transaksi nyata.

### 8.2  Manage Menu

| Menu | Aksi | Status |
|---|---|---|
| Detail Event | Membuka detail event | Selesai |
| Peserta | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Tiket | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Laporan | Snackbar "akan hadir di Fase Berikutnya" | Rencana |
| Scan QR Check-in | Membuka layar scan | Selesai (simulasi) |

### 8.3  Reporting Plan

Laporan organizer akan dihitung dari tabel `tickets` dan `transactions` di backend: jumlah tiket terjual, peserta, check-in, pendapatan, dan tingkat kehadiran per event. Grafik dan ekspor laporan belum termasuk cakupan saat ini.

### 8.4  Testing Status

| Test ID | Skenario | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| ORG-01 | Dashboard tampil pada mobile dan desktop | Semua kartu statistik dan menu tampil, tanpa overflow | Lulus (390 dan 1400) | Selesai |
| ORG-02 | Buka detail event dari menu organizer | Detail event tampil | Belum diuji otomatis | Belum diuji |
| ORG-03 | Statistik dari data transaksi nyata | Angka sesuai database | Belum ada backend | Rencana |

---

## 9  Testing, Optimization, and Deployment

Bagian ini memuat hasil pengujian aktual, batasannya, serta rencana optimasi dan rilis.

### 9.1  Testing Strategy and Traceability

Pengujian saat ini berfokus pada widget test untuk memastikan layar utama tampil lengkap dan bebas overflow pada berbagai ukuran. Test case diturunkan dari requirement functional (FR) dan dijalankan dengan data mock.

Perintah verifikasi:

```bash
flutter analyze
flutter test
```

### 9.2  Actual Test Results

| Item | Hasil |
|---|---|
| Tanggal eksekusi | 22 Oktober 2026 |
| `flutter analyze` | No issues found (0 issue) |
| `flutter test` | 21 lulus, 0 gagal |
| Jumlah file test | 3 file: `ui_smoke_test.dart`, `event_grid_card_test.dart`, `widget_test.dart` |
| Ukuran layar teruji | 390x844, 768x1024, 1080x800, 1366x620, 1400x900 |
| Pengujian perangkat fisik | Belum dilakukan |
| Pengujian API/backend | Belum dapat dilakukan |
| Pengujian unit perhitungan | Belum ada |

Rincian pengujian otomatis:

| Test ID | Kelompok | Jumlah Kasus | Hasil | Status |
|---|---|---|---|---|
| WT-01 | Detail Event lengkap (3 ukuran) | 3 | Lulus | Selesai |
| WT-02 | Tiket Saya + QR (2 ukuran) | 2 | Lulus | Selesai |
| WT-03 | Checkout lengkap (3 ukuran) | 3 | Lulus | Selesai |
| WT-04 | Scan Screen bebas overflow (3 ukuran) | 3 | Lulus | Selesai |
| WT-05 | Organizer Dashboard (2 ukuran) | 2 | Lulus | Selesai |
| WT-06 | MainNavigation semua tab (3 ukuran) | 3 | Lulus | Selesai |
| WT-07 | EventGridCard bebas overflow (4 ukuran) | 4 | Lulus | Selesai |
| WT-08 | Boot aplikasi ke splash | 1 | Lulus | Selesai |

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

**Gambar 11.** Tangkapan layar output `flutter test` (21/21 lulus). Status: placeholder; screenshot terminal aktual menyusul.

### 9.3  Regression Findings and Fixes

Selama pengembangan ditemukan beberapa masalah layout dan satu masalah konsistensi file. Semua sudah diperbaiki dan diverifikasi ulang:

| No | Temuan | Dampak | Perbaikan | Status |
|---|---|---|---|---|
| 1 | Kartu tiket memakai tinggi grid tetap 540 px | Overflow 21 px pada 390 dan 1400 | Tinggi adaptif `600 * textScaler` | Diperbaiki |
| 2 | Baris quick filter Jelajahi terlalu lebar di 390 | Overflow 9,8 px | Susunan kolom + chip dapat digulir pada layar sempit | Diperbaiki |
| 3 | Badge "Member Prioritas EventKuy" tidak fleksibel | Overflow 43 px pada 390 | Teks memakai `Flexible` dan ellipsis | Diperbaiki |
| 4 | File detail event sempat kembali ke versi lama | Konten detail tidak sesuai desain dan test gagal | File ditulis ulang sesuai desain | Diperbaiki |
| 5 | Baris total checkout berisiko overflow pada font uji | Overflow pada ukuran sempit | Baris total memakai `Wrap` | Diperbaiki |

Catatan teknis: widget test Flutter memakai font Ahem yang membuat lebar/tinggi teks berbeda dari font asli, sehingga beberapa overflow hanya muncul di test. Perbaikan dilakukan agar layout tetap aman pada kedua kondisi.

### 9.4  Testing Not Yet Performed

| Area | Test yang Belum Ada | Rencana |
|---|---|---|
| Unit test | Format rupiah, tanggal, perhitungan total/diskon | Buat `test/unit` dengan data deterministik |
| API integration | CRUD event/tiket, validasi voucher | Setelah backend Laravel tersedia |
| Authentication | Login server, token kedaluwarsa, logout | Setelah Sanctum |
| Database | Constraint, kepemilikan data, check-in ganda | Setelah migrasi MySQL |
| Kamera | Izin, pemindaian QR, cahaya rendah | Setelah `mobile_scanner` diaktifkan |
| Perangkat | Instalasi APK, notch, gesture bar, Back | Fase rilis |
| Performa | Waktu muat, jumlah request, memori | Setelah API nyata |

### 9.5  Optimization and Robustness

- Gambar memakai cache dan fallback otomatis bila aset lokal tidak tersedia.
- Grid event memakai rasio adaptif per breakpoint (0,60 / 0,82 / 0,90).
- Konten dibatasi maksimum 1200 px agar tetap nyaman di desktop.
- Area filter dan tab yang berpotensi sempit dibuat dapat digulir.
- Tinggi kartu tiket mengikuti skala teks pengguna.
- `flutter analyze` dipertahankan pada nol issue.
- Scratch test debug sudah dihapus; jumlah pengujian aktif menjadi 21.

### 9.6  Build and Deployment

| Item | Status |
|---|---|
| Application ID | `com.ajangin.app` |
| Label Android | `EventKuy` |
| Versi | 1.0.0+1 |
| Signing Android | Belum dikonfigurasi |
| Izin INTERNET manifest utama | Belum ditambahkan (hanya ada di manifest debug) |
| Build APK/AAB | Belum dibangun |
| Emulator/perangkat Android | Belum diuji |
| Play Store | Belum dimulai |

Langkah rilis yang direncanakan: menambahkan izin INTERNET dan kamera, membuat signing key, membangun AAB, menguji pada perangkat fisik, menyiapkan kebijakan privasi dan aset store, lalu mengunggah ke Play Console.

### 9.7  Risks and Mitigation

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Backend belum ada | Seluruh data masih mock; aplikasi belum dapat dipakai nyata | Prioritaskan Fase backend Laravel dan kontrak API |
| Auth masih lokal | Data pengguna tidak aman | Ganti ke Sanctum dan penyimpanan token aman |
| Pembayaran simulasi | Tiket tidak benar-benar dibeli | Integrasi Midtrans sandbox lebih dahulu |
| Check-in lokal | Tiket dapat dipalsukan | Validasi kode di server dan idempotensi check-in |
| Izin rilis belum lengkap | APK rilis gagal mengakses jaringan/kamera | Lengkapi manifest dan Info.plist sebelum build |
| Perubahan file tak terduga | Kode dapat kembali ke versi lama | Commit rutin dan review diff sebelum push |
| Belum ada unit test | Kesalahan perhitungan tidak terdeteksi | Tambah unit test sebelum backend |

### 9.8  Final Project Evaluation

Frontend EventKuy sudah mencapai tahap yang dapat didemonstrasikan: seluruh layar utama tersedia, alur beli tiket berjalan dalam mode simulasi, dan kualitas layout dijaga oleh 21 widget test. Namun aplikasi belum dapat dinyatakan selesai sebagai produk karena autentikasi, database, pembayaran, kamera, dan rilis belum diimplementasikan.

Evaluasi mengikuti prinsip bukti: fitur yang dinyatakan selesai hanya fitur yang memiliki kode dan hasil uji yang tercatat. Fitur yang masih mock dinyatakan sebagai mock, bukan selesai penuh.

### 9.9  Final Application Overview

Artefak yang tersedia saat ini:

1. Repositori Flutter dengan 36 file Dart di `lib/` (7.630 baris) dan 3 file test.
2. Dokumen desain dan kebutuhan: `DESIGN_SPEC.md`.
3. Laporan progress ini.
4. Data mock 7 event dan 7 gambar aset lokal.
5. Hasil verifikasi `flutter analyze` dan `flutter test`.

Artefak yang masih harus dilengkapi: screenshot aplikasi, hasil build APK, bukti pengujian perangkat, backend, dan integrasi pembayaran.

---

## Checklist Bukti Implementasi Laporan

| Deliverable | Required Evidence | Status |
|---|---|---|
| System design | Architecture, use case, navigation, ERD (rancangan) | Sebagian (diagram teks, ERD rencana) |
| Frontend implementation | Kode, screenshot, hasil test | Kode dan test tersedia; screenshot pending |
| Authentication | Alur login/register/logout | Mock selesai; server pending |
| Database | Skema dan hasil migrasi | Belum ada |
| REST API | Endpoint dan hasil uji | Belum ada |
| Payment | Integrasi Midtrans dan bukti transaksi | Belum ada |
| QR and check-in | QR, validasi kamera/server | QR selesai; kamera/server pending |
| Security | Uji otorisasi dan kepemilikan data | Belum ada |
| Testing | Test case dengan hasil aktual | Widget test 21/21; unit/API/device pending |
| Release | APK build dan uji perangkat | Belum ada |
| Documentation | Laporan progress, README, design spec | Tersedia |

---

## Daftar Referensi

Referensi resmi untuk verifikasi implementasi. Tanggal akses ditambahkan saat sumber benar-benar diperiksa.

[1] Flutter Team, "Flutter Documentation." https://docs.flutter.dev/
[2] Dart Team, "Dart Documentation." https://dart.dev/guides
[3] Flutter Team, "Testing Flutter apps." https://docs.flutter.dev/testing
[4] pub.dev, "provider — Flutter package." https://pub.dev/packages/provider
[5] pub.dev, "shared_preferences — Flutter package." https://pub.dev/packages/shared_preferences
[6] pub.dev, "qr_flutter — Flutter package." https://pub.dev/packages/qr_flutter
[7] pub.dev, "cached_network_image — Flutter package." https://pub.dev/packages/cached_network_image
[8] pub.dev, "http — Dart package." https://pub.dev/packages/http
[9] pub.dev, "mobile_scanner — Flutter package." https://pub.dev/packages/mobile_scanner
[10] Laravel, "Laravel Documentation." https://laravel.com/docs
[11] Laravel, "Sanctum Documentation." https://laravel.com/docs/sanctum
[12] Oracle, "MySQL Documentation." https://dev.mysql.com/doc/
[13] Midtrans, "Midtrans Documentation." https://docs.midtrans.com/
[14] Google, "Publish your app." https://support.google.com/googleplay/android-developer/answer/9859152

---

## Lampiran A — Struktur Proyek

```text
ajangin/
  assets/
    fonts/            (Manrope 5 bobot, DM Sans 4 bobot)
    images/           (7 poster event)
  lib/                (36 file Dart, 7.630 baris)
    core/             (config, responsive, theme)
    models/           (event, ticket, user)
    providers/        (auth, event, favorite, ticket)
    screens/          (13 tampilan + shell navigasi)
    services/         (mock_api_service)
    widgets/          (10 komponen reusable)
  test/
    ui_smoke_test.dart
    event_grid_card_test.dart
    widget_test.dart
  android/            (label EventKuy, applicationId com.ajangin.app)
  ios/                (display name EventKuy)
  web/                (title dan manifest EventKuy)
  DESIGN_SPEC.md
  README.md
  LAPORAN_PROGRESS.md
  pubspec.yaml
```

---

## Lampiran B — Konsistensi Field Model, Database, dan JSON

Tabel ini menjadi acuan agar model Dart, JSON, dan kolom database tidak menyimpang saat backend dibuat.

| Entity | Rencana kolom database/JSON | Atribut Dart saat ini | Tipe/Relasi |
|---|---|---|---|
| User | id, name, email | id, name, email | int, string, string |
| Event | id, title, description, date, location, price, quota, image_url, category, tags, time_range | id, title, description, date, location, price, quota, imageUrl, category, tags, timeRange | int, string, datetime, int |
| Ticket | code, event_id, event_title, status | code, eventId, eventTitle, status | string, int, string, enum status |
| Favorite | user_id, event_id | Set<int> pada provider | relasi user-event |
| Transaction | order_id, user_id, event_id, ticket_id, subtotal, admin_fee, discount, total, payment_method, status | Belum ada model | int rupiah |

Aturan konsistensi:

1. JSON memakai `snake_case`; Dart memakai `camelCase` dengan mapping eksplisit.
2. `tickets.code` harus unik dan dibuat server.
3. `tickets.status` hanya boleh `pending`, `paid`, atau `checked_in`.
4. Nilai uang disimpan sebagai integer rupiah.
5. Setiap endpoint privat memeriksa kepemilikan `user_id` di server.
6. `image_url` dapat berupa aset lokal pada fase mock dan URL HTTPS pada fase produksi.

---

## Lampiran C — Prosedur Reproduksi Verifikasi

```bash
# 1. Ambil dependensi
flutter pub get

# 2. Analisis statis
flutter analyze

# 3. Jalankan seluruh test
flutter test

# 4. Jalankan aplikasi pada Chrome
flutter run -d chrome

# 5. Cek lingkungan pengembangan
flutter doctor
```

Hasil yang diharapkan pada kondisi saat ini:

```text
flutter analyze  -> No issues found
flutter test     -> 21 tes lulus
```

Catatan: pengujian widget memakai font uji sehingga hasil visualnya tidak identik dengan aplikasi sebenarnya. Verifikasi visual tetap perlu dilakukan pada Chrome/emulator dengan `flutter run` (bukan hot reload setelah perubahan besar).

---

## Rencana Pengembangan Berikutnya

| Fase | Lingkup | Status | Keluaran |
|---|---|---|---|
| A | Redesign UI, rebrand EventKuy, perbaikan layout, pengujian dasar | Selesai | Frontend mock, 21 test lulus |
| B | Verifikasi visual, screenshot, commit dan push | Berjalan | Bukti visual dan riwayat git |
| C | Backend Laravel dan MySQL (migrasi, seed, CRUD event) | Rencana | REST API dan database |
| D | Integrasi API di Flutter (auth, event, favorit, tiket) | Rencana | Data nyata menggantikan mock |
| E | Midtrans (checkout, webhook, status tiket) | Rencana | Pembayaran sandbox berfungsi |
| F | Kamera QR, validasi check-in server, PDF tiket, organizer riil | Rencana | Check-in dan e-ticket lengkap |
| G | Build AAB, uji perangkat, Play Store | Rencana | Rilis Android |

Estimasi progres keseluruhan bersifat indikatif: frontend mendominasi capaian saat ini, sedangkan backend, pembayaran, dan rilis belum dimulai.
