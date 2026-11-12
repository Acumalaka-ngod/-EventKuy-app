# Todo — Profil EventKuy

Spec: `docs/SPEC-profile.md`
Plan: `tasks/plan.md`

Status: implementasi selesai. Verifikasi otomatis (`flutter analyze`,
`flutter test`, build web) lulus. Tersisa migrasi Supabase dan uji manual.

## Phase 1 — Foundation & Data

- [x] Task 1: Model `TransactionRecord` + `fetchTransactions` (kontrak, Supabase, Mock)
  - Acceptance: mock checkout menghasilkan satu transaksi per tiket; Supabase join `tickets(code)` + `events(title)`
  - Verify: `flutter analyze`, test mock transaksi
  - Files: `lib/models/transaction_record.dart`, `lib/services/api_service.dart`, `lib/services/supabase_api.dart`, `lib/services/mock_api_service.dart`
- [x] Task 2: `AppUser.avatarUrl`, `AuthProvider.updateProfile/changePassword`, `AvatarService`, `supabase/avatars.sql`
  - Acceptance: profil bisa di-update tanpa logout; upload mengembalikan public URL
  - Verify: `flutter analyze`
  - Files: `lib/models/user.dart`, `lib/providers/auth_provider.dart`, `lib/services/avatar_service.dart`, `supabase/avatars.sql`
  - [x] Validasi avatar hanya JPG/PNG/WebP (GIF ditolak) lewat magic bytes + ekstensi + MIME di client dan `AvatarService`
  - [x] Bucket `avatars` dibatasi `file_size_limit` 5 MB dan `allowed_mime_types` di server

## Phase 2 — Identity

- [x] Task 3: `EditProfileScreen`
  - Acceptance: nama kosong/1 karakter ditolak; foto >5 MB ditolak; simpan sukses memperbarui provider
  - Verify: `flutter test test/edit_profile_test.dart` — 6 test lulus
  - Files: `lib/screens/profile/edit_profile_screen.dart`, `test/edit_profile_test.dart`
- [x] Task 4: `ProfileScreen` + `SettingsScreen`
  - Acceptance: statistik Check-in nyata; badge sesuai role; gear membuka Pengaturan; menu aktif
  - Verify: `flutter test test/profile_screen_test.dart` — 9 test lulus
  - Files: `lib/screens/profile/profile_screen.dart`, `lib/screens/profile/settings_screen.dart`, `test/profile_screen_test.dart`

## Phase 3 — Security

- [x] Task 5: `ChangePasswordScreen`
  - Acceptance: validasi panjang/konfirmasi/password lama; sukses mengosongkan form
  - Verify: `flutter test test/change_password_test.dart` — 6 test lulus
  - Files: `lib/screens/profile/change_password_screen.dart`, `test/change_password_test.dart`

## Phase 4 — History

- [x] Task 6: `TransactionHistoryScreen`
  - Acceptance: daftar terbaru dulu, format Rupiah, chip status, metode pembayaran, empty state, pull-to-refresh
  - Verify: `flutter test test/transaction_history_test.dart` — 4 test lulus
  - Files: `lib/screens/profile/transaction_history_screen.dart`, `test/transaction_history_test.dart`

## Phase 5 — Help

- [x] Task 7: `HelpCenterScreen`
  - Acceptance: minimal 8 FAQ dalam 3 kategori, accordion, pencarian, empty state
  - Verify: `flutter test test/help_center_test.dart` — 4 test lulus
  - Files: `lib/screens/profile/help_center_screen.dart`, `test/help_center_test.dart`

## Batch 1 — Perbaikan UI/UX Profil

- [x] C1/C2: semantics + target sentuh 48 pada gear, kamera avatar, Ganti Foto, dan Coba Lagi
- [x] H1: kontras `textFaint` dan `amber` memenuhi AA; token `amberSoft` untuk chip Menunggu
- [x] H2: label field terbaca pembaca layar (nama, email, peran, ketiga field password)
- [x] H3: error validasi inline lewat `InputDecoration.errorText` + fokus ke field invalid; error server lewat banner `liveRegion`, bukan SnackBar
- Verify: `flutter test test/profile_contrast_test.dart`, `test/profile_screen_test.dart`, `test/edit_profile_test.dart`, `test/change_password_test.dart`, `test/transaction_history_test.dart`

## Batch 2 — Perbaikan UI/UX Beranda & Keamanan

- [x] H5: avatar beranda punya label "Buka profil", tombol notifikasi berlabel "Notifikasi", keduanya target sentuh 48
- [x] Toggle password berubah antara "Lihat password" dan "Sembunyikan password" (tooltip + semantics) dengan target 48
- Verify: `flutter test test/home_topbar_test.dart`, `test/change_password_test.dart`, `test/avatar_service_test.dart`, `test/edit_profile_test.dart`

## Perbaikan Share Event

- [x] Tombol bagikan benar-benar menyalin info event (judul, tanggal/waktu, lokasi, harga) ke clipboard, bukan hanya menampilkan SnackBar
- Verify: `flutter test test/event_share_test.dart`

## Final Verification

- [x] `flutter analyze` — No issues found
- [x] `flutter test` — 120 test lulus
- [x] `flutter build web --release --dart-define-from-file=supabase.local.json` — sukses
- [x] Jalankan `supabase/avatars.sql` versi awal (bucket + policy Storage)
- [ ] Jalankan ulang `supabase/avatars.sql` untuk batas MIME/ukuran di bucket
- [x] Jalankan `supabase/qty_voucher_stock.sql`
- [ ] Uji manual: edit profil, avatar (termasuk tolak GIF), password, riwayat transaksi, FAQ

---

# Todo — P1 UI/UX Remediation (Audit 6.1/10)

Plan: `tasks/plan.md` — bagian **P1 UI/UX Remediation**.
Status: rencana disetujui, implementasi belum dimulai.

## Phase 1 — Interaction & Accessibility

- [x] Task 1: `AppIconButton` + tombol navigasi/filter (semantics, tooltip, target 48, keyboard)
  - Verify: `test/accessibility_controls_test.dart` (6 test), `test/ui_smoke_test.dart`, `flutter analyze`
- [x] Task 2A: Hati favorit, opsi pembayaran, qty, dan Lihat Semua
  - Verify: `test/selection_controls_test.dart`, `test/favorite_hold_test.dart`, `test/ui_smoke_test.dart`
- [x] Task 2B: Chip kategori Beranda/Jelajahi dan quick filter
  - Verify: `test/selection_controls_test.dart` (7 test), `test/ui_smoke_test.dart`, `flutter analyze`
- [x] Task 2C: Tab tiket, hero banner, judul tiket, dan Unduh PDF
  - Verify: `test/selection_controls_test.dart` (11 test), `test/ui_smoke_test.dart`, `flutter analyze`

### Checkpoint 1
- [x] `flutter analyze` bersih
- [x] Test aksesibilitas + smoke lulus
- [x] Review keyboard Tab/Enter di 390 dan 768 (test otomatis)

## Phase 2 — Checkout & Search

- [x] Task 3: Checkout sticky + layout 768 + validasi/autofill pemesan
  - Verify: `test/checkout_form_test.dart` (8 test), `test/stock_soldout_test.dart`, `test/ui_smoke_test.dart`
- [x] Task 4: Sinkronisasi pencarian + error/empty state Beranda & Jelajahi
  - Verify: `test/search_sync_test.dart` (2 test), `test/home_states_test.dart` (3 test), `test/ui_smoke_test.dart`

### Checkpoint 2
- [x] `flutter analyze` bersih
- [x] Test checkout/search lulus
- [x] Review visual 390/768/1400 (smoke test)

## Phase 3 — Data States, Favorites, Navigation

- [x] Task 5: State tiket/favorit + hapus shelf + konfirmasi/undo Hapus Semua
  - Verify: `test/favorite_hold_test.dart` (2 test), `test/favorite_tab_sync_test.dart` (1 test), `test/data_state_test.dart` (8 test), `test/ui_smoke_test.dart`
- [x] Task 6: Label rail tablet + notifikasi empty state + hapus self check-in
  - Verify: `test/navigation_notifications_test.dart` (3 test), `test/ui_smoke_test.dart`, `test/ticket_watch_test.dart`

### Checkpoint 3
- [x] `flutter analyze` bersih
- [x] Test tiket/favorit/navigasi lulus
- [x] Review manual rail 768, notifikasi, QR attendee (test otomatis)

## Phase 4 — Auth Forms

- [x] Task 7: Validasi/autofill/aksesibilitas Login & Register
  - Verify: `test/auth_form_test.dart` (9 test), `flutter analyze`

### Checkpoint 4
- [x] `flutter analyze` bersih
- [x] Test auth lulus
- [x] Review error inline, autofill, dan target 48 di 390 (test otomatis)

## Phase 5 — Final Verification

- [x] Task 8: Update `DESIGN_SPEC.md`, `LAPORAN_PROGRESS.md`, `tasks/todo.md`
- [x] `flutter analyze` — No issues found
- [x] `flutter test` — 168 test lulus
- [x] `flutter build web --release --dart-define-from-file=supabase.local.json` — sukses
- [x] Catat temuan P2 yang tersisa
- [x] Catat skor audit: 6.1/10 sebelum P1 → 7.8/10 penilaian mandiri setelah P1 (belum audit independen)

---

# Todo — P2 (Fondasi, Konten, Checkout, Deep Link, Share, Notifikasi)

Spec: `docs/P2_CAPABILITY_MAP.md`, `docs/P2_MODULE_SPECS.md`
Plan: `tasks/plan.md` — bagian **P2 Implementation Plan**.
Status: belum dimulai.

## Phase 1 — Core

- [x] Task 1: Lokalisasi `id_ID`, format terpusat, reduced motion, token desain
  - Acceptance: locale aktif; format tetap; durasi nol saat reduced motion; token dipakai
  - Verify: `test/localization_test.dart`, `test/reduced_motion_test.dart`, `test/design_tokens_test.dart`, `flutter analyze`
  - Files: `pubspec.yaml`, `lib/main.dart`, `lib/core/formatters.dart`, `lib/core/motion.dart`, `lib/core/theme.dart`

### Checkpoint 1
- [x] `flutter analyze` bersih
- [x] Test core lulus (15 test)
- [x] Tidak ada regresi format tanggal/rupiah

## Phase 2 — Event Content

- [x] Task 2: Organizer + rating nyata
  - Acceptance: rating/organizer dari model; fallback tanpa migrasi; teks statis lama hilang
  - Verify: `test/event_content_test.dart`, `test/ui_smoke_test.dart`, `flutter analyze`
  - Files: `supabase/p2_event_content.sql`, `lib/models/organizer.dart`, `lib/models/event.dart`, `lib/screens/event/event_detail_screen.dart`

### Checkpoint 2
- [x] Test event content lulus (8 test)
- [x] Smoke 390/768/1400 lulus

## Phase 3 — Checkout Buyer

- [x] Task 3: Persistensi nama/email/WhatsApp pemesan
  - Acceptance: data tersimpan di transaksi; UI mengirim nilai form; RPC baru memuat tiga parameter buyer
  - Verify: `test/checkout_buyer_test.dart`, `test/checkout_form_test.dart`, `test/checkout_rules_test.dart`, `flutter analyze`
  - Files: `supabase/p2_checkout_buyer.sql`, `lib/models/transaction_record.dart`, `lib/services/*`, `lib/providers/ticket_provider.dart`, `lib/screens/checkout/checkout_screen.dart`

### Checkpoint 3
- [x] Test checkout lama dan baru lulus
- [x] Tidak ada pemanggil checkout tanpa buyer di aplikasi

## Phase 4 — Deep Link

- [x] Task 4: Parser/generator tautan + host + konfigurasi platform
  - Acceptance: scheme dan web hash terurai; tautan tertunda dibuka setelah MainNavigation siap
  - Verify: `test/deep_link_test.dart`, `flutter analyze`
  - Files: `lib/core/deep_link.dart`, `lib/providers/deep_link_provider.dart`, `lib/widgets/deep_link_host.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

### Checkpoint 4
- [x] Unit parsing lulus (11 test)
- [x] Konfigurasi Android/iOS diterapkan

## Phase 5 — Share

- [x] Task 5: Share sheet + fallback clipboard
  - Acceptance: teks berisi tautan event; kegagalan gateway menyalin ke clipboard
  - Verify: `test/event_share_test.dart`, `flutter analyze`
  - Files: `lib/services/share_service.dart`, `lib/screens/event/event_detail_screen.dart`

### Checkpoint 5
- [x] Test share lulus (3 test)
- [x] Web build sukses
- [ ] Verifikasi share sheet perangkat dicatat pending

## Phase 6 — Notifications Scaffold

- [x] Task 6: Token table, feed in-app, provider, abstraksi push
  - Acceptance: feed tampil; unread badge nyata; mark-read; token no-op tidak error; empty state tetap
  - Verify: `test/notification_feed_test.dart`, `test/navigation_notifications_test.dart`, `flutter analyze`
  - Files: `supabase/p2_notifications.sql`, `lib/models/app_notification.dart`, `lib/providers/notification_provider.dart`, `lib/services/push_messaging_service.dart`, `lib/screens/home/home_screen.dart`

### Checkpoint 6
- [x] Test notifikasi lulus (5 test)
- [x] Push live dinyatakan belum terverifikasi

## Phase 7 - Final Verification

- [ ] Task 7: Dokumentasi + Definition of Done
  - Verify: `flutter analyze`, `flutter test`, `flutter build web --release --dart-define-from-file=supabase.local.json`
- [ ] `flutter analyze` - bersih
- [ ] `flutter test` - seluruh test lulus (259 test)
- [ ] Web build sukses
- [ ] Item belum terverifikasi live dicatat di LAPORAN_PROGRESS.md

## Phase 8 - Organizer Event CRU

- [x] Task 8: Form buat/edit event + upload poster
  - Acceptance: organizer bisa mengubah nama, deskripsi, kategori, tanggal, jam, lokasi, harga, kuota, dan poster; poster diunggah ke Storage dan URL tersimpan di `events.image_url`
  - Verify: `test/event_crud_test.dart`, `test/event_image_service_test.dart`, `test/organizer_event_editor_test.dart`, `flutter analyze`
  - Files: `lib/models/event_draft.dart`, `lib/services/api_service.dart`, `lib/services/supabase_api.dart`, `lib/services/mock_api_service.dart`, `lib/services/image_validation.dart`, `lib/services/event_image_service.dart`, `lib/providers/event_provider.dart`, `lib/screens/organizer/organizer_event_editor_screen.dart`, `lib/screens/organizer/organizer_dashboard_screen.dart`, `supabase/organizer_events.sql`

### Checkpoint 8
- [x] Test CRU event + validasi gambar + editor lulus (28 test)
- [x] Dashboard menampilkan semua event organizer dan tombol Buat Event Baru
- [x] Form 390x844 tidak overflow
- [ ] Migrasi `supabase/organizer_events.sql` dijalankan di Supabase Studio
- [ ] Upload poster live diverifikasi di perangkat/browser dengan akun organizer

## Phase 9 - Navigasi Role-Aware Organizer

- [x] Task 9: Dashboard sebagai Beranda organizer + Scan QR besar di tengah navbar
  - Acceptance: organizer hanya melihat Beranda (dashboard), Scan QR, dan Profil; tab pembeli tidak dirender; rail tablet dan sidebar desktop memakai aksi Scan QR menonjol; deep link event diabaikan; profil organizer bebas fitur pembeli; splash/login tidak memuat tiket/favorit organizer
  - Verify: `test/organizer_navigation_test.dart`, `test/profile_screen_test.dart`, `flutter test` (266 lulus), `flutter analyze`, web release build
  - Files: `lib/screens/main_navigation.dart`, `lib/screens/profile/profile_screen.dart`, `lib/screens/organizer/organizer_dashboard_screen.dart`, `lib/screens/splash/splash_screen.dart`, `lib/screens/auth/login_screen.dart`, `test/organizer_navigation_test.dart`, `test/profile_screen_test.dart`

### Checkpoint 9
- [x] Navigasi organizer mobile/tablet/desktop lulus (6 test)
- [x] Profil organizer tidak menampilkan statistik pembeli, Riwayat Transaksi, atau Mode Organizer
- [x] Deep link event dikonsumsi tanpa membuka Detail Event untuk organizer
- [x] `flutter analyze` bersih, 266 test lulus, web release build sukses
