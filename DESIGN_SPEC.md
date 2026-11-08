# EVENTKUY — Design Spec (Handoff UI/UX)

> Versi dokumen: 1.2 · Status: **P1 remediation selesai; P2 selesai (tanpa dark mode)** · Platform: Flutter (Android utama, tablet/desktop/web didukung)

---

## 0. Cara Pakai Dokumen Ini

Dokumen ini adalah **acuan fungsi, menu, konten, alur, dan kebutuhan teknis** aplikasi EventKuy.

- **Bebas diubah oleh desainer (redesign total):** warna, tipografi, bentuk komponen, ilustrasi, ikonografi, gaya visual secara keseluruhan.
- **Wajib dipertahankan:** struktur 5 tab navigasi, 13 tampilan beserta alur antarlayar, semua *state* (loading, kosong, sukses, gagal), konten minimum per layar, dan persyaratan responsif (Bagian 7).
- **Status implementasi P1:** validasi form auth inline, autofill, banner error server, target sentuh 48 px, rail tablet berlabel, state error/retry tiket & favorit, konfirmasi + undo Hapus Semua Favorit, dan checkout sticky sudah diterapkan.
- **Status implementasi P2 (tanpa dark mode):** lokalisasi `id_ID` + helper format terpusat, reduced motion, normalisasi token desain, organizer + rating nyata di Detail Event, persistensi data pembeli (nama/email/WhatsApp) di transaksi, deep link `eventkuy://event/<id>` dan web `/#/event/<id>`, native share sheet + fallback clipboard, dan scaffold notifikasi (token table + feed in-app; push live ditunda menunggu kredensial Firebase). Dark mode tidak dikerjakan.
- Lampiran di Bagian 11 berisi token visual versi lama — **opsional**, hanya referensi bila ingin mempertahankan sesuatu.

---

## 1. Identitas & Positioning

| Item | Detail |
|---|---|
| Nama | **EventKuy** |
| Tagline | **Temukan • Ikuti • Hadiri** |
| Deskripsi | Aplikasi event discovery & e-ticketing: konser musik, seminar, workshop, event olahraga |
| Target pengguna | 18–35 tahun, urban, aktif mencari hiburan & pengembangan diri |
| Model bisnis | Jual tiket + biaya layanan per transaksi, voucher promo |
| Platform | Android (Play Store) — Flutter; layout tablet/desktop/web juga diresponsifkan |
| Bahasa | Indonesia |

---

## 2. Peta Navigasi & Daftar Tampilan

```
Splash
 └─ auto-login? → Beranda / Login
Login ⇄ Register
MainNavigation (5 tab):
 ├─ 0 Beranda ─→ Detail Event ─→ Checkout ─→ [Dialog Sukses] ─→ Tiket Saya
 ├─ 1 Jelajahi ─→ Detail Event
 ├─ 2 Tiket Saya
 ├─ 3 Favorit ─→ Detail Event
 └─ 4 Profil
Bottom sheet: Pilih Kota · Konfirmasi Keluar
```

**13 tampilan yang harus dirancang:**

| # | Tampilan | Bagian |
|---|---|---|
| 1 | Splash | 3.1 |
| 2 | Login | 3.2 |
| 3 | Register | 3.3 |
| 4 | Shell Navigasi (bottom bar / rail / sidebar) | 3.4 |
| 5 | Beranda | 3.5 |
| 6 | Jelajahi | 3.6 |
| 7 | Tiket Saya | 3.7 |
| 8 | Favorit | 3.8 |
| 9 | Profil | 3.9 |
| 10 | Detail Event | 3.10 |
| 11 | Checkout | 3.11 |
| 12 | Dialog Sukses Pembayaran | 3.12 |
| 13 | Bottom Sheets (Pilih Kota, Konfirmasi Logout) | 3.13 |

---

## 3. Detail Per Layar

### 3.1 Splash

**Tujuan:** branding singkat saat membuka aplikasi (tampil ±2 detik), lalu otomatis mengarahkan ke Beranda (jika sudah pernah login) atau Login.

**Konten wajib:**
- Logo aplikasi (besar, center) + wordmark **EVENTKUY**
- Tagline "TEMUKAN • IKUTI • HADIRI"
- Teks versi: "Versi 1.0.0 • Mobile Event Ticketing"

**Interaksi/animasi:** logo muncul dengan animasi scale + fade; transisi ke layar berikutnya berupa fade halus. Tidak ada aksi dari user.

---

### 3.2 Login

**Tujuan:** masuk akun dengan email dan password Supabase Auth.

**Konten wajib:**
- Logo + wordmark kecil di atas
- Sapaan: **"Selamat Datang Kembali"** + subteks ajakan
- Form: **Email** dan **Password** (dengan toggle lihat/sembunyikan password)
- Checkbox **"Ingat saya"** + link **"Lupa Password?"**
- Tombol utama **"Masuk Sekarang"**
- Divider "Atau masuk dengan" + tombol **Google** dan **Apple** (belum berfungsi)
- Footer: "Belum memiliki akun? **Daftar Sekarang**" (→ Register)

**Interaksi:**
- Tombol masuk menampilkan loading di dalam tombol, lalu pindah ke Beranda
- Validasi inline: email wajib + format email, password wajib; fokus berpindah ke field pertama yang salah
- Field memakai autofill hint email/password dan `AutofillGroup`
- Error server tampil di **FormErrorBanner** (live region), bukan SnackBar
- "Lupa Password?" memvalidasi email lalu memanggil reset password Supabase
- Checkbox, link "Lupa Password?", dan "Daftar Sekarang" punya target sentuh minimal 48 px
- Toggle password memakai tooltip dinamis "Lihat password" / "Sembunyikan password"

**State:** default · loading (tombol disabled + spinner) · error validasi inline · error server (banner).

**Catatan platform:** di desktop, layout **split view** — panel kiri branding + panel kanan form (max 480px). Di HP/tablet, form di tengah.

---

### 3.3 Register

**Tujuan:** daftar akun baru.

**Konten wajib:**
- Judul **"Mulai Petualanganmu"** + subteks
- Form: **Nama Lengkap**, **Email**, **Password**, **Konfirmasi Password**
- Checkbox **setuju Syarat & Ketentuan** — default **tidak dicentang**
- Tombol **"Daftar Sekarang"**
- Footer: "Sudah punya akun? **Masuk**" (→ kembali)

**Interaksi:**
- Validasi inline: nama wajib/minimal 2 karakter, email wajib/format valid, password wajib/minimal 8 karakter, konfirmasi harus sama, dan terms wajib dicentang
- Field memakai autofill hint nama/email/password baru
- Error server tampil di **FormErrorBanner**, bukan SnackBar
- Sukses dengan sesi aktif → Beranda; sukses tanpa sesi → notifikasi hijau + kembali ke Login
- Tombol dan link punya target sentuh minimal 48 px
- Toggle password memakai tooltip dinamis

**State:** default · loading · error validasi inline · error server (banner) · sukses.

---

### 3.4 Shell Navigasi (pembungkus 5 tab)

**Tujuan:** kerangka utama setelah login; menampilkan 5 menu:

| Tab | Label | Ikon | Badge |
|---|---|---|---|
| 0 | Beranda | home | — |
| 1 | Jelajahi | compass/explore | — |
| 2 | Tiket | tiket | jumlah tiket aktif |
| 3 | Favorit | hati | jumlah favorit |
| 4 | Profil | orang | — |

**Perilaku responsif (wajib):**
- **HP (<720px):** bottom navigation bar floating, ikon + label, item aktif diberi highlight pill
- **Tablet (720–1100px):** navigation rail vertikal kiri selebar **96px**, setiap item menampilkan ikon + label teks (bukan hanya tooltip), target sentuh 72×64
- **Desktop (>1100px):** sidebar penuh (lebar 240px) berisi logo + nama app "EVENTKUY", 5 item menu berlabel + badge angka, footer teks versi "EventKuy v1.0.0 • Temukan. Ikuti. Hadiri."

**Badge:** bulatan merah dengan angka (maks "9+") di atas ikon. Badge hanya tampil bila ada data nyata; tidak ada badge palsu.

---

### 3.5 Beranda (tab 0) — layar terpenting

**Tujuan:** personalisasi & konversi — memperlihatkan event unggulan dan terdekat.

**Konten wajib (urut atas ke bawah):**
1. **Top bar:** label kecil "LOKASI SAYA" + nama kota + panah dropdown (→ bottom sheet Pilih Kota); ikon **notifikasi** di kanan (membuka bottom sheet, bukan badge palsu); **avatar** user (inisial huruf pertama) dengan label "Buka profil"
2. **Sapaan:** "Hai, {nama depan} 👋" + kalimat ajakan singkat
3. **Search bar** besar (ikon search + tombol filter di kanan)
4. **Hero banner:** kartu besar event unggulan — poster full, badge **"FEATURED"** 🔥, tanggal di pojok, chip kategori, judul (putih, besar), lokasi, tombol bulat dengan ikon panah (CTA)
5. **5 ikon kategori:** Semua · Konser · Seminar · Workshop · Olahraga — ikon dalam kotak membulat, ikon aktif berbeda jelas
6. **Section "Event Terdekat Untukmu 🔥"** + subteks + link **"Lihat Semua"**
7. **Grid kartu poster** (2 kolom di HP, 3–4 di layar besar), maks 4 event. Setiap kartu: poster, badge kategori, tombol hati (overlay), tanggal, judul, kota, harga

**Interaksi:** tap hero/kartu → Detail Event; tap kategori → filter; tap "Lihat Semua" → pindah tab Jelajahi; pull-to-refresh; notifikasi → bottom sheet empty state "Belum Ada Notifikasi".

**State:** loading (spinner) · terisi · error jaringan (pesan + **Coba Lagi**) · hasil pencarian kosong (saran + reset). Pencarian Beranda dan Jelajahi memakai satu sumber kebenaran (`EventProvider.query`) sehingga field tetap sinkron saat berpindah tab.

---

### 3.6 Jelajahi (tab 1)

**Tujuan:** pencarian & filter seluruh event.

**Konten wajib:**
- Judul halaman "Jelajahi Event"
- **Search bar** ("Ketik nama acara, artis, atau kota...")
- **Baris chip kategori** (Semua, Konser, Seminar, Workshop, Olahraga) — bisa di-scroll horizontal, satu aktif
- **Quick filter:** Semua / Terpopuler / Terdekat + counter "N Event"
- **Daftar event:** di HP = kartu horizontal (poster kecil kiri, info kanan, tombol bookmark kanan); di layar ≥600px = grid poster

**State kosong:** ilustrasi + "Tidak Ada Event Ditemukan" + saran + tombol **Reset Pencarian**.
**State error:** pesan jaringan + tombol **Coba Lagi**, bukan empty state.

**Interaksi:** tap kartu → Detail Event; ketik di search → hasil live; tap kategori → filter.

---

### 3.7 Tiket Saya (tab 2)

**Tujuan:** pusat e-ticket milik user.

**Konten wajib:**
- Judul "Tiket & Pass Saya"
- **3 tab filter:** Semua / Aktif / Selesai (dengan angka)
- **Kartu E-Ticket bergaya boarding pass** (lihat Bagian 4 — TicketItem):
  - Header: label "EVENTKUY PASS", badge status **TIKET AKTIF** / **SUDAH CHECK-IN**, judul event, jadwal + ikon jam
  - Garis perforasi putus-putus + lekukan (cutout) kiri-kanan seperti tiket fisik
  - **QR code** (fungsi asli, bisa dipindai), kode teks "TICKET ID: AJG-…"
  - Instruksi **"Tunjukkan QR ini ke petugas"** untuk attendee. Tombol check-in mandiri **tidak ada** karena RPC `check_in_ticket` hanya mengizinkan organizer pemilik event; check-in dilakukan lewat Mode Petugas/Scan QR
  - Kartu kecil: "Pemilik: {nama}" + link **Unduh PDF** (menghasilkan e-tiket PDF asli)
- Layout: 1/2/3 kolom sesuai lebar layar

**State kosong:** ilustrasi + "Belum Ada Tiket Terdaftar" + tombol **Cari Event Sekarang**.
**State error:** "Gagal Memuat Tiket" + pesan + tombol **Coba Lagi**.

---

### 3.8 Favorit (tab 3)

**Tujuan:** daftar event yang disimpan (bookmark).

**Konten wajib:**
- Judul "Event Tersimpan"
- Baris "N Event Disimpan" + link **Hapus Semua** (warna bahaya)
- Daftar/grid kartu event yang sama dengan Jelajahi

**State kosong:** ilustrasi hati + "Belum Ada Favorit" + saran + tombol **Jelajahi Event**.
**State error:** "Gagal Memuat Favorit" + pesan + tombol **Coba Lagi**.

**Interaksi:** tap kartu → Detail; toggle bookmark → kartu **langsung hilang** dari daftar. "Hapus Semua" membuka dialog konfirmasi berisi jumlah event; setelah dikonfirmasi, SnackBar **"Urungkan"** mengembalikan favorit yang baru dihapus.

---

### 3.9 Profil (tab 4)

**Konten wajib:**
- Judul "Profil Saya" + ikon pengaturan (kanan atas)
- **Kartu profil:** avatar inisial besar (dengan tombol ganti foto overlay), nama, email, badge **"Member Prioritas EventKuy"** (ikon mahkota/medali)
- **3 kartu statistik:** Tiket Saya (jumlah) · Favorit (jumlah) · Poin Reward (contoh: 1.250) — masing-masing dengan ikon berwarna
- **Grup "Akun & Aktivitas":** Edit Informasi Profil · Riwayat Pesanan & Transaksi · Metode Pembayaran Tersimpan
- **Grup "Bantuan & Pusat Informasi":** Pusat Bantuan & FAQ · Hubungi Customer Care · Ketentuan Layanan & Privasi
- **Tombol "Keluar dari Akun"** (gaya bahaya lembut) → bottom sheet konfirmasi

**Interaksi:** item menu belum berfungsi (bisa tampil snackbar "segera hadir"); logout → konfirmasi dulu.

**Catatan platform:** konten dibatasi lebar 760px & di tengah pada layar besar.

---

### 3.10 Detail Event

**Tujuan:** halaman konversi — semua info event + CTA beli.

**Konten wajib:**
1. **Hero image** besar (poster) dengan tombol overlay: kembali, bagikan, simpan/hati; indikator "1/4 Foto"; overlay gelap agar teks terbaca
2. Chip **kategori** + badge rating bintang (contoh: "4.9 (320 ulasan)")
3. **Judul event** (besar, bold)
4. **Kartu tanggal & waktu** (ikon kalender + tanggal lengkap + jam "15:00 - 23:00 WIB")
5. **Kartu lokasi** (ikon pin + **alamat lengkap venue sebagai teks** — aplikasi TIDAK memakai peta/Google Maps; pastikan alamat panjang tetap muat & rapi, boleh multi-baris)
6. **Kartu organizer** (avatar, nama penyelenggara + centang terverifikasi, tombol **Ikuti/Diikuti**)
7. Section **"Tentang Acara"** (deskripsi paragraf)
8. **Tagar** event (chip, contoh #Musik #Festival)
9. **Bottom bar sticky:** "Harga Tiket" + harga (besar) + tombol utama **"Daftar & Beli Tiket"** — selalu terlihat saat scroll

**Interaksi:** tap hati → toggle favorit; tombol beli → Checkout; tombol share → salin info event (judul, jadwal, lokasi, harga) ke clipboard, native share menyusul.

**Catatan platform:** konten dibatasi 860px pada layar besar.

---

### 3.11 Checkout & Pembayaran

**Tujuan:** konfirmasi pesanan + pilih metode bayar + bayar.

**Konten wajib (urut):**
1. **Step indicator:** (1) Pilih → (2) Bayar → (3) E-Tiket — step aktif ditandai jelas
2. **Kartu ringkasan event:** thumbnail + kategori + judul + "12 Jul 2025 • 1x Regular Pass"
3. **Form "Informasi Pemesan":** Nama Lengkap, Email Konfirmasi Tiket, Nomor WhatsApp/HP
4. **"Pilih Metode Pembayaran"** — 3 opsi radio-card:
   - **GoPay / GoPay Later** — "Bebas biaya admin & konfirmasi instan"
   - **BCA / Mandiri Virtual Account** — "Transfer otomatis via m-Banking atau ATM"
   - **Kartu Kredit / Debit Online** — "Visa, Mastercard, & JCB dengan 3D Secure"
   - Opsi terpilih: border tebal + ikon centang bulat
5. **Voucher promo:** field input "Punya voucher? Cth: AJANGSERU" + tombol **Gunakan**. Kode valid: `AJANGSERU` / `DISKON10` → diskon **Rp 25.000** (notifikasi hijau); kode salah → notifikasi merah
6. **Rincian Biaya:** Harga Tiket + Biaya Layanan & Sistem (Rp 2.500) − Diskon (hijau, bila ada) = **Total Pembayaran** (menonjol)
7. **Trust badge:** 🔒 "Pembayaran 100% Aman & Terenkripsi"
8. **Tombol bayar:** "Bayar Sekarang • Rp XXX.XXX" (loading saat diproses)

**State:** default · loading pembayaran · voucher valid/tidak valid · error validasi inline · error server (banner).

**Catatan platform:** desktop ≥1024px = 2 kolom (kiri: form & metode; kanan: rincian biaya + tombol bayar). Di bawah 1024px = 1 kolom dengan **CTA sticky** di bawah layar agar tombol bayar selalu terlihat tanpa menggulir. Data pemesan divalidasi inline dan memakai autofill; data pembeli belum dipersist ke database karena RPC `checkout` hanya menerima event, qty, voucher, dan metode pembayaran.

---

### 3.12 Dialog Sukses Pembayaran (modal)

**Konten wajib:** ikon centang besar (warna sukses), judul **"Pembayaran Berhasil! 🎉"**, teks "E-tiket untuk {nama event} telah diterbitkan dan tersimpan di menu Tiket Saya", tombol **"Lihat Tiket Saya"** (→ pindah ke tab Tiket). Dialog tidak bisa ditutup dengan tap di luar.

---

### 3.13 Bottom Sheets

**a. Pilih Kota** — daftar 4 kota: Jakarta, Bandung, Surabaya, Yogyakarta. Kota terpilih ditandai centang + warna aksen. Tap → ganti lokasi di Beranda.

**b. Konfirmasi Keluar** — ikon logout, judul "Konfirmasi Keluar", teks pertanyaan, 2 tombol: **Batal** (outline) dan **Ya, Keluar** (bahaya).

**c. Notifikasi** — bottom sheet dari ikon lonceng Beranda. Berisi judul "Notifikasi", penjelasan singkat, empty state **"Belum Ada Notifikasi"**, dan tombol "Tutup". Belum ada badge notifikasi palsu; push notification menyusul di P2.

**d. Hapus Semua Favorit** — dialog konfirmasi berisi jumlah event, tombol **Batal** / **Hapus**, lalu SnackBar **"Urungkan"**.

---

## 4. Komponen Reusable (rancang variannya)

| Komponen | Deskripsi | Varian |
|---|---|---|
| **EventGridCard** | Kartu poster untuk grid: gambar 16:10 + badge kategori + tombol hati overlay + tanggal, judul, kota, harga | normal · favorited |
| **EventCard** | Kartu horizontal untuk list: gambar persegi kiri + info + bookmark | normal · favorited |
| **HeroBanner** | Kartu besar event unggulan + overlay gradien + badge FEATURED | — |
| **TicketItem** | E-ticket boarding pass (header berwarna, perforasi, QR, instruksi QR) | aktif · checked-in |
| **AppIconButton** | Tombol ikon standar dengan label semantics, tooltip, dan target 48 px | solid · outline · ghost |
| **FormErrorBanner** | Error form tingkat layar, dibacakan sebagai live region | — |
| **AppSearchBar** | Input pencarian rounded + ikon filter | dengan/tanpa tombol filter |
| **CategoryChip** | Chip pill filter kategori | aktif · nonaktif |
| **CategoryIconItem** | Ikon kategori kotak + label | aktif · nonaktif |
| **SectionHeader** | Judul section + subteks + link "Lihat Semua" | dengan/tanpa subteks/link |
| **PaymentOption** | Radio-card metode pembayaran | terpilih · tidak |
| **CustomButton** | Tombol utama | solid (gradient) · outline · loading · dengan ikon |
| **Badge angka** | Notifikasi jumlah pada ikon tab | angka 1–9 · "9+" |
| **Snackbar/Toast** | Notifikasi sementara | sukses (hijau) · error (merah) · info |
| **Empty State** | Tampilan saat data kosong | 3 varian: pencarian, favorit, tiket |
| **Error State** | Tampilan saat pemuatan gagal | pesan + Coba Lagi (tiket, favorit, beranda, jelajahi) |
| **Bottom Sheet** | Panel bawah | list pilihan · konfirmasi destruktif · notifikasi |

---

## 5. User Journey Utama

1. **Buka aplikasi pertama kali:** Splash → Login → isi nama & email → Beranda
2. **Beli tiket:** Beranda → tap event (hero/kartu) → Detail Event → "Daftar & Beli Tiket" → isi data pemesan → pilih metode → (opsional pakai voucher) → Bayar → Dialog Sukses → Tiket Saya (QR muncul)
3. **Cari event:** tab Jelajahi → ketik kata kunci / pilih kategori → tap kartu → Detail
4. **Simpan favorit:** tap ikon hati di kartu/hero/detail → cek di tab Favorit → tap → Detail
5. **Check-in di venue:** tab Tiket → tunjukkan QR → petugas membuka Mode Petugas, scan QR dengan kamera (atau input kode manual) → status berubah "SUDAH CHECK-IN" (hijau)
6. **Keluar akun:** tab Profil → "Keluar dari Akun" → konfirmasi → Login

---

## 6. Konten & Data Dummy (untuk mock-up)

**7 event contoh:**

| Event | Kategori | Harga | Lokasi |
|---|---|---|---|
| Sound of Tomorrow | Konser | Rp 750.000 | Istora Senayan, Jl. Pintu Satu Senayan No. 1, Jakarta Pusat |
| We The Fest 2025 | Konser | Rp 750.000 | Gelora Bung Karno (GBK), Jl. Pintu Satu Senayan, Jakarta Pusat |
| Photography Workshop | Workshop | Rp 250.000 | Braga Creative Hub, Jl. Braga No. 21, Bandung |
| Future of Technology | Seminar | Rp 150.000 | Jakarta Convention Center, Jl. Gatot Subroto, Jakarta Pusat |
| Jakarta Running Festival | Olahraga | Rp 300.000 | Kawasan Monas, Jl. Silang Monas, Jakarta Pusat |
| UI/UX Design Workshop | Workshop | Rp 200.000 | GoWork Chubb Square, Jl. M.H. Thamrin No. 10, Jakarta Pusat |
| Digital Marketing Summit | Seminar | Rp 350.000 | Gedung Merdeka, Jl. Asia Afrika No. 65, Bandung |

**Data lain:** user demo "Andi Pratama / andi@eventkuy.id" · voucher `EVENTKUY` & `DISKON10` (diskon Rp 25.000) · biaya layanan Rp 2.500 · status tiket: `pending` / `paid` / `checked_in` · poin reward contoh "1.250".

---

## 7. Persyaratan Responsif & Platform

| Breakpoint | Lebar | Navigasi | Grid event |
|---|---|---|---|
| Mobile | < 720px | Bottom bar | 2 kolom |
| Tablet | 720–1100px | Rail kiri 96px berlabel | 3 kolom |
| Desktop | > 1100px | Sidebar 240px | 4 kolom |

**Aturan umum:**
- Lebar konten maksimal **1200px**, selalu di tengah pada layar besar
- Padding konten: 18px (HP) / 28px (tablet) / 32px (desktop)
- Target sentuh minimum **48×48px**; hormati safe area (notch/gesture bar)
- Kartu tiket (Tiket Saya): 1 kolom <620px, 2 kolom sampai ~1100px, 3 kolom di atasnya
- Checkout: CTA sticky di bawah 1024px, dua kolom pada ≥1024px
- Semua layar harus punya state: **loading, terisi, kosong, error** (jaringan)

---

## 8. Checklist Aset Handoff dari Desainer

| # | Aset | Spesifikasi |
|---|---|---|
| 1 | Logo mark + wordmark + versi putih | SVG + PNG @1x/2x/3x |
| 2 | 7 poster event | rasio **16:10** (mis. 1600×1000), JPG/PNG < 500KB |
| 3 | Ikon 5 kategori | grid 24px, outline + filled |
| 4 | Ikon 5 tab navigasi | outline (nonaktif) + filled (aktif) |
| 5 | Ilustrasi empty state ×3 | pencarian, favorit, tiket (skema seragam) |
| 6 | Ilustrasi sukses pembayaran | untuk dialog 3.12 |
| 7 | Logo metode pembayaran | GoPay, BCA VA, Mandiri VA, Visa/Mastercard/JCB |
| 8 | Logo sosial | Google, Apple |
| 9 | App icon | 512×512 (Play Store) + adaptive icon Android (foreground + background terpisah) |
| 10 | Splash screen | ikon di atas background (Android 12+ splash screen API) |
| 11 | (Opsional) Onboarding 3 panel | ilustrasi user baru |

---

## 9. Fitur Mendatang (rancang layout-nya dari sekarang)

- ~~Peta lokasi event (Google Maps) + tombol "Petunjuk Arah"~~ **DIBATALKAN** — tanpa Google Maps API; lokasi hanya ditampilkan sebagai teks alamat lengkap di semua layar
- ~~**Mode scanner QR petugas** (kamera full-screen + frame scan + riwayat scan)~~ **SELESAI** — kamera asli lewat `mobile_scanner`, input kode manual, dan animasi garis scan
- **Notifikasi push** + halaman daftar notifikasi (ikon lonceng di Beranda sudah membuka bottom sheet empty state)
- **Native share sheet / deep link** untuk event (saat ini tombol bagikan menyalin info event ke clipboard)
- **Dark mode, lokalisasi (`flutter_localizations`), dan reduced motion** — menunggu persetujuan dependency/desain P2
- **Halaman voucher/promo** (daftar promo aktif)
- **Layar menu Profil yang belum ada:** Metode Pembayaran Tersimpan, Pusat Bantuan, Customer Care, Syarat & Privasi. Edit Profil, Riwayat Transaksi, dan Ubah Password sudah tersedia
- **Halaman Organizer** (profil penyelenggara + daftar event-nya, dari tombol "Ikuti")
- ~~**Unduh e-ticket PDF** (tombol sudah ada di kartu tiket)~~ **SELESAI** — PDF A5 ber-QR via package `pdf` + `printing`

---

## 10. Lampiran — Token Visual Versi Lama (OPSIONAL, tidak wajib diikuti)

> Hanya referensi. Karena arah redesign = bebas, desainer boleh mengabaikan seluruh lampiran ini.

- **Warna:** Primary `#4F46E5` · Secondary coral `#FF5364` · Amber `#F59E0B` · Emerald `#10B981` · Navy `#0F172A` · Background `#F8FAFC` · Border `#E2E8F0`
- **Gradien:** `#4F46E5→#7C3AED` (tombol/logo) · `#312E81→#4F46E5→#7C3AED` (e-ticket & panel login)
- **Radius:** kartu 16–24px · chip pill · tombol 16px
- **Tipografi:** font sistem, skala 10–32px, bobot 500–900
- **Shadow:** lembut (opacity ≤8%, blur 8–20px)

---

*Dokumen ini dibuat dari kondisi kode aplikasi EventKuy v1.0.0. Pertanyaan teknis implementasi: `lib/core/theme.dart` (tema), `lib/core/responsive.dart` (breakpoint), `lib/screens/` (layar).*
