# Implementation Plan: Profil EventKuy

## Overview

Melengkapi tab Profil: edit nama + avatar (Supabase Storage), ganti password,
riwayat transaksi, statistik/badge nyata, halaman Pengaturan, dan Pusat Bantuan
& FAQ. Semua fitur memakai tema, pola provider, dan layer API yang sudah ada.

## Architecture Decisions

- **Avatar disimpan di Storage, bukan base64 di database.** Bucket `avatars`
  publik untuk baca, policy insert/update/delete dibatasi folder `auth.uid()`.
  `profiles.avatar_url` menyimpan public URL.
- **Update profil lewat `AuthProvider`.** `profiles.name`/`avatar_url` di-update
  langsung, lalu metadata auth disinkronkan lewat `auth.updateUser`.
- **Riwayat transaksi lewat `EventKuyApi`.** SupabaseApi memakai join
  `tickets(code)` dan `events(title)`; MockApiService meniru RPC checkout
  (satu transaksi per tiket, diskon hanya di tiket pertama).
- **Tidak ada dependency baru.** `image_picker`, `intl`, dan `url_launcher`
  sudah tersedia.
- **Layar baca-saja memakai API injection.** `TransactionHistoryScreen` menerima
  `EventKuyApi?` agar bisa diuji dengan `MockApiService`.
- **Menu yang tidak dipilih dihapus dari UI.** "Metode Pembayaran" dan
  "Hubungi CS" dihapus supaya tidak ada menu mati.

## Task List

### Phase 1: Foundation & Data

- [x] Task 1: Model `TransactionRecord` + `fetchTransactions` di kontrak,
      SupabaseApi, dan MockApiService (termasuk transaksi saat checkout).
- [x] Task 2: `AppUser.avatarUrl`, `AuthProvider.updateProfile`,
      `AuthProvider.changePassword`, `AvatarService`, migrasi `avatars.sql`.

### Checkpoint: Foundation
- [x] `flutter analyze` bersih
- [x] Test mock transaksi lulus

### Phase 2: Identity

- [x] Task 3: `EditProfileScreen` (nama, avatar, validasi, upload) + test.
- [x] Task 4: `ProfileScreen` (avatar, statistik Check-in, badge role, menu
      aktif) + `SettingsScreen` + test.

### Checkpoint: Identity
- [ ] Edit profil tersimpan dan kartu profil berubah (uji manual)
- [x] Gear membuka Pengaturan

### Phase 3: Security

- [x] Task 5: `ChangePasswordScreen` + test validasi.

### Phase 4: History

- [x] Task 6: `TransactionHistoryScreen` + test daftar/empty state.

### Phase 5: Help

- [x] Task 7: `HelpCenterScreen` (FAQ + pencarian) + test.

### Checkpoint: Complete
- [x] `flutter analyze` tanpa issue
- [x] `flutter test` semua lulus (90 test)
- [x] `flutter build web --release` sukses
- [ ] Verifikasi manual dengan Supabase setelah `avatars.sql` dijalankan

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Bucket `avatars` belum dibuat | Tinggi | Pesan ramah + dokumentasi `avatars.sql` |
| Policy Storage salah | Tinggi | Path selalu `<user_id>/...`; uji upload manual |
| `image_picker` gagal di web | Sedang | Galeri sebagai jalur utama; tangkap error |
| Data transaksi kosong | Sedang | Empty state; checkout harus berhasil dulu |
| `context` dipakai setelah async | Sedang | Cek `mounted`/`context.mounted` sebelum navigasi |

## Open Questions

Tidak ada — tiga pertanyaan spec sudah disetujui dengan default.

---

# Implementation Plan: P1 UI/UX Remediation (Audit 6.1/10)

## Overview

Menutup seluruh temuan P1 audit UI/UX: kontrol kustom yang ramah keyboard dan
pembaca layar, target sentuh minimum 48 px, checkout yang bisa dipakai di HP
dan tablet 768, validasi/autofill form, state error/empty yang jujur,
sinkronisasi pencarian, perilaku favorit, label rail tablet, notifikasi, dan
self check-in attendee. Tidak ada dependency baru.

## Architecture Decisions

- **Satu widget tombol ikon.** `AppIconButton` membungkus `IconButton`/`InkWell`
  dengan `tooltip`, `Semantics`, dan target minimum 48 px. Semua tombol ikon
  kustom memakai widget ini agar perilaku keyboard dan pembaca layar konsisten.
- **Satu CTA checkout.** Di bawah 1024 px, tombol bayar menjadi sticky bottom
  bar; di atas 1024 px, CTA tetap di kartu ringkasan. Layout 768 memakai satu
  kolom agar tidak terpotong.
- **Data pemesan tidak dipalsukan.** Nama/email hanya di-prefill dari akun.
  Form memakai `Form`, validator inline, `AutofillGroup`, dan fokus ke field
  pertama yang invalid. RPC `checkout` belum menyimpan data pemesan; persistensi
  backend dicatat sebagai follow-up, bukan bagian P1.
- **Pencarian punya satu sumber kebenaran.** `EventProvider.query` menjadi
  sumber kebenaran; controller di Beranda dan Jelajahi disinkronkan lewat
  listener provider.
- **Favorit langsung hilang saat dilepas.** Shelf tertunda dihapus karena
  membingungkan. "Hapus Semua" memakai dialog konfirmasi dan aksi "Urungkan".
- **Self check-in attendee dihapus dari UI.** RPC `check_in_ticket` hanya
  mengizinkan organizer pemilik event; attendee cukup menunjukkan QR.
- **Notifikasi jujur.** Tombol notifikasi membuka bottom sheet empty state;
  badge palsu dihapus sampai ada sistem notifikasi nyata.

## Task List

### Phase 1: Interaction & Accessibility

- [x] **Task 1: Widget `AppIconButton` + tombol navigasi/filter**
  - Description: Buat widget tombol ikon aksesibel dan terapkan pada tombol
    kembali, bagikan, favorit detail, filter pencarian, serta tombol clear.
  - Acceptance:
    - [x] Semua tombol ikon punya label semantics dan tooltip.
    - [x] Target sentuh minimal 48x48 px.
    - [x] Bisa difokuskan dan diaktifkan lewat keyboard.
  - Verification: `flutter test test/accessibility_controls_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: None.
  - Files: `lib/widgets/app_icon_button.dart`,
    `lib/screens/checkout/checkout_screen.dart`,
    `lib/screens/event/event_detail_screen.dart`,
    `lib/screens/ticket/my_tickets_screen.dart`,
    `lib/screens/favorite/favorite_screen.dart`,
    `lib/screens/explore/explore_screen.dart`,
    `lib/widgets/app_search_bar.dart`,
    `test/accessibility_controls_test.dart`.
  - Estimated scope: Medium (7 files + test).

- [x] **Task 2A: Hati favorit, opsi pembayaran, qty, dan Lihat Semua**
  - Description: Ganti `GestureDetector` pada kontrol pilihan dengan kontrol
    yang punya semantics, state selected/disabled, dan target 48.
  - Acceptance:
    - [x] Hati favorit mengumumkan "Simpan ke favorit"/"Hapus dari favorit"
      dan status `toggled`; target 48 dengan visual tetap 36.
    - [x] Opsi pembayaran mengumumkan status selected dan bisa diaktifkan
      lewat keyboard.
    - [x] Tombol +/- qty mengumumkan aksi dan status disabled.
    - [x] Tombol "Lihat Semua" punya target minimal 48.
  - Verification: `flutter test test/selection_controls_test.dart`,
    `flutter test test/favorite_hold_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 1 (pola widget/semantics).
  - Files: `lib/widgets/event_card.dart`, `lib/widgets/payment_option.dart`,
    `lib/screens/checkout/checkout_screen.dart`, `lib/widgets/section_header.dart`,
    `test/selection_controls_test.dart`.
  - Estimated scope: Medium (4 file + test).

- [x] **Task 2B: Chip kategori dan quick filter**
  - Description: Jadikan chip kategori Beranda/Jelajahi dan quick filter
    sebagai kontrol aksesibel dengan status selected dan target 48.
  - Acceptance:
    - [x] `CategoryChip` mengumumkan label + selected dan target 48.
    - [x] `CategoryIconItem` mengumumkan label + selected dan target 48;
      baris kategori Beranda tidak overflow.
    - [x] Quick filter Jelajahi mengumumkan label + selected dan target 48.
  - Verification: `flutter test test/selection_controls_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 2A.
  - Files: `lib/widgets/category_chip.dart`, `lib/screens/home/home_screen.dart`,
    `lib/screens/explore/explore_screen.dart`, `test/selection_controls_test.dart`.
  - Estimated scope: Small/Medium (3 file + test).

- [x] **Task 2C: Tab tiket, hero, dan aksi tiket**
  - Description: Tab tiket, hero banner, judul tiket, dan Unduh PDF memakai
    semantics serta target sentuh yang benar.
  - Acceptance:
    - [x] Tab tiket mengumumkan label + jumlah + selected dan target 48.
    - [x] Hero banner mengumumkan "Lihat detail <judul>" dan bisa diaktifkan
      lewat keyboard.
    - [x] Judul tiket bisa diaktifkan lewat keyboard.
    - [x] Tombol Unduh PDF punya target minimal 48.
  - Verification: `flutter test test/selection_controls_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 2A.
  - Files: `lib/screens/ticket/my_tickets_screen.dart`,
    `lib/widgets/hero_banner.dart`, `lib/widgets/ticket_item.dart`,
    `test/selection_controls_test.dart`.
  - Estimated scope: Small/Medium (3 file + test).

### Checkpoint: Interaction & Accessibility
- [x] `flutter analyze` bersih.
- [x] Test aksesibilitas + smoke test lulus.
- [x] Review manual: Tab/Enter pada tombol ikon di 390 dan 768 (test otomatis).

### Phase 2: Checkout & Search

- [x] **Task 3: Checkout sticky, layout 768, dan validasi pemesan**
  - Description: Perbaiki layout checkout agar CTA selalu terjangkau, hapus
    data pemesan palsu, dan validasi form dengan autofill.
  - Acceptance:
    - [x] Di 390x844 dan 768x1024, CTA terlihat tanpa menggulir dan tidak
      overflow.
    - [x] Di 1400x900, layout tetap dua kolom.
    - [x] Nama kosong, email kosong/invalid, dan HP invalid menampilkan error
      inline serta fokus ke field pertama yang salah.
    - [x] Tidak ada lagi default "Andi Pratama", "andi@eventkuy.id", atau
      "0812 3456 7890".
    - [x] Field punya autofill hint yang sesuai.
    - [x] Error API tampil inline, bukan hanya SnackBar.
  - Verification: `flutter test test/checkout_form_test.dart`,
    `flutter test test/stock_soldout_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 1 (tombol ikon header).
  - Files: `lib/screens/checkout/checkout_screen.dart`,
    `test/checkout_form_test.dart`, `test/stock_soldout_test.dart`,
    `test/ui_smoke_test.dart`.
  - Estimated scope: Medium (1 layar + 3 test).

- [x] **Task 4: Sinkronisasi pencarian + state error/empty Beranda & Jelajahi**
  - Description: Jadikan `EventProvider.query` sumber kebenaran, sinkronkan
    controller pencarian, dan tampilkan error/empty state yang berbeda.
  - Acceptance:
    - [x] Mengetik di Jelajahi langsung terlihat di field Beranda, dan sebaliknya.
    - [x] Clear pencarian mengosongkan kedua field dan hasil.
    - [x] Saat load gagal dan data kosong, muncul pesan error + tombol Coba Lagi,
      bukan "Event Tidak Ditemukan".
    - [x] Empty state hanya muncul saat load sukses tetapi hasil kosong.
    - [x] Controller internal `AppSearchBar` di-dispose dengan benar.
  - Verification: `flutter test test/search_sync_test.dart`,
    `flutter test test/home_states_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 3 tidak wajib, tetapi checkpoint Phase 2 menunggu keduanya.
  - Files: `lib/providers/event_provider.dart`, `lib/screens/home/home_screen.dart`,
    `lib/screens/explore/explore_screen.dart`, `lib/widgets/app_search_bar.dart`,
    `test/search_sync_test.dart`, `test/home_states_test.dart`.
  - Estimated scope: Medium (4 file + 2 test).

### Checkpoint: Checkout & Search
- [x] `flutter analyze` bersih.
- [x] Test checkout/search lulus.
- [x] Review visual 390/768/1400: CTA, error state, dan field pencarian (test otomatis).

### Phase 3: Data States, Favorites, Navigation

- [x] **Task 5: State tiket/favorit + perilaku favorit**
  - Description: Tambahkan state loading/error yang jujur pada tiket dan
    favorit, hapus shelf tertunda, dan beri konfirmasi/undo pada Hapus Semua.
  - Acceptance:
    - [x] Gagal memuat tiket menampilkan pesan + Coba Lagi, bukan empty state.
    - [x] Gagal memuat favorit menampilkan pesan + Coba Lagi.
    - [x] Melepas favorit langsung menghilangkan kartu dari layar Favorit.
    - [x] "Hapus Semua" membuka dialog konfirmasi dengan jumlah event.
    - [x] Setelah konfirmasi, SnackBar "Urungkan" mengembalikan favorit.
  - Verification: `flutter test test/favorite_hold_test.dart`,
    `flutter test test/favorite_tab_sync_test.dart`,
    `flutter test test/data_state_test.dart`,
    `flutter test test/ui_smoke_test.dart`, `flutter analyze`.
  - Dependencies: Task 2 (semantics hati favorit).
  - Files: `lib/providers/ticket_provider.dart`,
    `lib/providers/favorite_provider.dart`,
    `lib/screens/ticket/my_tickets_screen.dart`,
    `lib/screens/favorite/favorite_screen.dart`,
    `test/favorite_hold_test.dart`, `test/favorite_tab_sync_test.dart`,
    `test/data_state_test.dart`.
  - Estimated scope: Medium (4 file + 3 test).

- [x] **Task 6: Label rail tablet, notifikasi, dan self check-in**
  - Description: Tampilkan label di rail tablet, ganti tombol notifikasi mati
    dengan empty state yang jujur, dan hapus self check-in attendee.
  - Acceptance:
    - [x] Rail 720-1100 px menampilkan ikon + label teks.
    - [x] Tombol notifikasi membuka bottom sheet "Notifikasi" dengan empty state.
    - [x] Badge notifikasi palsu tidak lagi tampil.
    - [x] Layar tiket tidak lagi menampilkan tombol "Check-in Tiket".
    - [x] Layar tiket menampilkan instruksi "Tunjukkan QR ini ke petugas".
    - [x] Alur Scan QR organizer tetap berfungsi.
  - Verification: `flutter test test/navigation_notifications_test.dart`,
    `flutter test test/ui_smoke_test.dart`,
    `flutter test test/ticket_watch_test.dart`, `flutter analyze`.
  - Dependencies: Task 5 (state tiket).
  - Files: `lib/screens/main_navigation.dart`, `lib/screens/home/home_screen.dart`,
    `lib/widgets/ticket_item.dart`, `lib/screens/ticket/my_tickets_screen.dart`,
    `test/navigation_notifications_test.dart`, `test/ui_smoke_test.dart`.
  - Estimated scope: Medium (4 file + 2 test).

### Checkpoint: Data States, Favorites, Navigation
- [x] `flutter analyze` bersih.
- [x] Test tiket/favorit/navigasi lulus.
- [x] Review manual: rail 768, notifikasi, dan QR attendee (test otomatis).

### Phase 4: Auth Forms

- [x] **Task 7: Validasi, autofill, dan aksesibilitas Login/Register**
  - Description: Samakan kualitas form auth dengan form profil: validator
    inline, autofill, error banner, target 48, dan terms tidak pre-checked.
  - Acceptance:
    - [x] Login dengan field kosong/email invalid menampilkan error inline.
    - [x] Register menolak nama <2 karakter, email invalid, password <8,
      konfirmasi tidak cocok, dan terms belum dicentang — semuanya inline.
    - [x] Checkbox "Ingat saya", link "Lupa Password?", dan "Daftar Sekarang"
      punya target minimal 48.
    - [x] Field punya autofill hint email/password/nama.
    - [x] Error server tampil di banner, bukan SnackBar.
    - [x] Toggle password punya tooltip dinamis.
  - Verification: `flutter test test/auth_form_test.dart`, `flutter analyze`.
  - Dependencies: Task 1 (pola tombol ikon) dan `FormErrorBanner` yang sudah ada.
  - Files: `lib/screens/auth/login_screen.dart`,
    `lib/screens/auth/register_screen.dart`, `test/auth_form_test.dart`.
  - Estimated scope: Medium (2 layar + test).

### Checkpoint: Auth Forms
- [x] `flutter analyze` bersih.
- [x] Test auth lulus (9 test).
- [x] Review error inline, autofill, dan target 48 di 390 (test otomatis).

### Phase 5: Verification & Documentation

- [x] **Task 8: Verifikasi akhir + dokumentasi**
  - Description: Perbarui dokumentasi dan jalankan Definition of Done.
  - Acceptance:
    - [x] `flutter analyze` — No issues found.
    - [x] `flutter test` — 168 test lulus.
    - [x] `flutter build web --release --dart-define-from-file=supabase.local.json`
      sukses.
    - [x] `DESIGN_SPEC.md`, `LAPORAN_PROGRESS.md`, dan `tasks/todo.md` diperbarui.
  - Verification: tiga perintah Definition of Done + review dokumen.
  - Dependencies: Tasks 1-7.
  - Files: `DESIGN_SPEC.md`, `LAPORAN_PROGRESS.md`, `tasks/todo.md`.
  - Estimated scope: Small.

### Checkpoint: Complete
- [x] Semua acceptance criteria P1 terpenuhi.
- [x] Tidak ada dependency baru.
- [x] Temuan P2 yang tersisa dicatat untuk sprint berikutnya.
- [x] Skor akhir: 6.1/10 (audit awal) → 7.8/10 (penilaian mandiri setelah P1).

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Perubahan perilaku favorit memecahkan test lama | Sedang | Update test sesuai perilaku baru; jangan hapus assertion |
| Sticky CTA tertutup keyboard | Sedang | Uji 390x844 dengan keyboard terbuka; gunakan `SafeArea` + `resizeToAvoidBottomInset` |
| Layout dua kolom di 1024 terlalu sempit | Sedang | Uji 1024 dan 1400; fallback ke satu kolom bila perlu |
| Menghapus self check-in dianggap mengurangi fitur | Rendah | RPC memang organizer-only; alur organizer tetap di Scan QR |
| Listener pencarian memicu loop | Sedang | Guard `if (controller.text != provider.query)` dan lepas listener di dispose |
| Test auth mengenai jaringan | Tinggi | Uji jalur validasi saja atau pakai fake `AuthProvider` |
| Data pemesan belum tersimpan di backend | Sedang | Catat sebagai follow-up; P1 hanya menghapus data palsu dan validasi UI |

## Open Questions

- **Persistensi data pemesan:** RPC `checkout` saat ini tidak menerima nama,
  email, atau HP pemesan. P1 hanya memperbaiki UI dan validasi. Jika data harus
  disimpan, perlu perubahan RPC/schema — minta persetujuan terpisah.
- **P2 yang sengaja ditunda:** dark mode, lokalisasi, reduced motion, native
  share/deep link, push notification, normalisasi token radius/warna, dan
  konten rating/organizer nyata.

---

# P2 Implementation Plan: Fondasi, Konten, Checkout, Deep Link, Share, Notifikasi

Spec: `docs/P2_CAPABILITY_MAP.md`, `docs/P2_MODULE_SPECS.md`.
Ruang lingkup: P2 tanpa dark mode. Firebase/push live ditunda.

## Architecture Decisions

- **Locale dipaksa `id_ID`.** Aplikasi berbahasa Indonesia; format tanggal/angka
  memakai helper terpusat di `lib/core/formatters.dart`.
- **Reduced motion dibaca dari `MediaQuery.disableAnimations`.** Tidak ada
  preferensi aplikasi terpisah; pengaturan aksesibilitas OS menjadi sumber.
- **Token desain dinormalisasi.** Radius/permukaan/overlay baru ditambahkan dan
  alias lama dipertahankan agar pemanggil lama tidak pecah.
- **Organizer dinormalisasi, ownership event tetap `events.organizer_id`.**
  Kolom baru `organizer_profile_id` menghubungkan event ke tabel `organizers`
  tanpa merusak RLS/check-in yang sudah memakai `organizer_id` sebagai pemilik.
- **Rating read-only.** Tidak ada tabel review atau UI kirim rating di P2.
- **Buyer data di `transactions`.** RPC `checkout` diperluas; versi lama
  di-drop agar PostgREST tidak ambigu.
- **Deep link memakai custom scheme + web hash.** `DeepLinkService.eventUri`
  menjadi satu-satunya pembuat tautan event.
- **Share memakai abstraksi gateway.** Implementasi `share_plus`; clipboard
  tetap fallback dan dapat diuji tanpa platform channel.
- **Notifikasi hanya scaffold.** Tabel token + feed in-app + abstraksi push;
  tidak ada dependency Firebase.

## Task List

### Phase 1: Core

- [ ] Task 1: Lokalisasi `id_ID`, helper format terpusat, reduced motion, token desain
  - Acceptance: locale `id_ID` aktif; `formatRp`/`formatTanggal` tetap benar;
    `AppMotion.duration` nol saat reduced motion; token radius/permukaan dipakai.
  - Verify: `flutter test test/localization_test.dart test/reduced_motion_test.dart test/design_tokens_test.dart`, `flutter analyze`.
  - Files: `pubspec.yaml`, `lib/main.dart`, `lib/core/formatters.dart`,
    `lib/core/motion.dart`, `lib/core/theme.dart`, `lib/widgets/event_card.dart`,
    `lib/screens/splash/splash_screen.dart`, `lib/screens/main_navigation.dart`.
  - Estimated scope: Medium.

### Checkpoint: Core
- [ ] `flutter analyze` bersih
- [ ] Test core lulus
- [ ] Tidak ada regresi format tanggal/rupiah

### Phase 2: Event Content

- [ ] Task 2: Schema organizer/rating + model + API + UI Detail Event
  - Acceptance: rating dan organizer berasal dari model; fallback aman bila
    migrasi belum dijalankan; tombol "Ikuti" palsu dihapus.
  - Verify: `flutter test test/event_content_test.dart test/ui_smoke_test.dart`, `flutter analyze`.
  - Files: `supabase/p2_event_content.sql`, `lib/models/organizer.dart`,
    `lib/models/event.dart`, `lib/services/supabase_api.dart`,
    `lib/services/mock_api_service.dart`, `lib/screens/event/event_detail_screen.dart`.
  - Estimated scope: Medium.

### Checkpoint: Event Content
- [ ] Test event content lulus
- [ ] Smoke test Detail Event di 390/768/1400 lulus

### Phase 3: Checkout Buyer

- [ ] Task 3: Persistensi buyer di schema, RPC, model, provider, UI
  - Acceptance: nama/email/WhatsApp tersimpan di transaksi mock; UI mengirim
    nilai form; RPC baru memuat tiga parameter buyer.
  - Verify: `flutter test test/checkout_buyer_test.dart test/checkout_form_test.dart test/checkout_rules_test.dart`, `flutter analyze`.
  - Files: `supabase/p2_checkout_buyer.sql`, `lib/models/transaction_record.dart`,
    `lib/services/api_service.dart`, `lib/services/supabase_api.dart`,
    `lib/services/mock_api_service.dart`, `lib/providers/ticket_provider.dart`,
    `lib/screens/checkout/checkout_screen.dart`.
  - Estimated scope: Medium.

### Checkpoint: Checkout Buyer
- [ ] Test checkout lama dan baru lulus
- [ ] Tidak ada pemanggil RPC checkout tanpa buyer di aplikasi

### Phase 4: Deep Link

- [ ] Task 4: Parser/generator tautan, provider antrean, host, konfigurasi platform
  - Acceptance: `eventkuy://event/<id>` dan `/#/event/<id>` terurai; tautan
    tertunda dibuka setelah MainNavigation siap.
  - Verify: `flutter test test/deep_link_test.dart`, `flutter analyze`.
  - Files: `pubspec.yaml`, `lib/core/deep_link.dart`,
    `lib/providers/deep_link_provider.dart`, `lib/widgets/deep_link_host.dart`,
    `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`,
    `ios/Runner/Info.plist`.
  - Estimated scope: Medium.

### Checkpoint: Deep Link
- [ ] Unit parsing lulus
- [ ] Konfigurasi Android/iOS diperiksa manual

### Phase 5: Share

- [ ] Task 5: Share sheet + fallback clipboard
  - Acceptance: gateway menerima teks berisi tautan event; kegagalan gateway
    menyalin ke clipboard; snackbar sesuai hasil.
  - Verify: `flutter test test/event_share_test.dart`, `flutter analyze`.
  - Files: `pubspec.yaml`, `lib/services/share_service.dart`,
    `lib/screens/event/event_detail_screen.dart`, `test/event_share_test.dart`.
  - Estimated scope: Small.

### Checkpoint: Share
- [ ] Test share lulus
- [ ] Verifikasi share sheet perangkat dicatat sebagai pending

### Phase 6: Notifications Scaffold

- [ ] Task 6: Token table, feed in-app, provider, abstraksi push
  - Acceptance: feed tampil dari API; unread badge nyata; mark-read bekerja;
    token no-op tidak error; empty state lama tetap.
  - Verify: `flutter test test/notification_feed_test.dart test/navigation_notifications_test.dart`, `flutter analyze`.
  - Files: `supabase/p2_notifications.sql`, `lib/models/app_notification.dart`,
    `lib/services/api_service.dart`, `lib/services/supabase_api.dart`,
    `lib/services/mock_api_service.dart`, `lib/services/push_messaging_service.dart`,
    `lib/providers/notification_provider.dart`, `lib/screens/home/home_screen.dart`,
    `lib/main.dart`.
  - Estimated scope: Medium.

### Checkpoint: Notifications
- [ ] Test notifikasi lulus
- [ ] Pengiriman push live dinyatakan belum terverifikasi

### Phase 7: Final Verification

- [ ] Task 7: Dokumentasi + Definition of Done
  - Acceptance: `flutter analyze` bersih; seluruh test lulus; web build sukses;
    dokumen diperbarui; item belum terverifikasi dicatat.
  - Verify: tiga perintah Definition of Done.
  - Files: `DESIGN_SPEC.md`, `LAPORAN_PROGRESS.md`, `tasks/plan.md`, `tasks/todo.md`.
  - Estimated scope: Small.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Migrasi Supabase belum dijalankan | Tinggi | Fallback select tanpa join; SQL idempotent; catat langkah manual |
| Overload RPC checkout ambigu | Tinggi | Drop signature lama sebelum membuat yang baru |
| Buyer fields memecahkan test lama | Sedang | Parameter opsional di Dart; UI selalu mengirim; test mock tetap jalan |
| `app_links`/`share_plus` gagal di platform | Sedang | Abstraksi gateway + fallback clipboard; verifikasi perangkat dicatat |
| Reduced motion mengubah animasi global | Rendah | Hanya durasi; test khusus |
| Feed notifikasi memecahkan empty state | Sedang | Empty state dipertahankan; badge hanya bila unread > 0 |
| Firebase dianggap selesai | Sedang | Nyatakan scaffold-only dan belum terverifikasi di laporan |
