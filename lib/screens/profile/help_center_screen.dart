import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Pusat Bantuan & FAQ statis. Pencarian menyaring pertanyaan dan jawaban.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqEntry> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _faqEntries;

    return _faqEntries
        .where(
          (entry) =>
              entry.question.toLowerCase().contains(query) ||
              entry.answer.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Ada yang bisa kami bantu?',
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cari jawaban seputar pembelian tiket, check-in, dan akun.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('faq-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari pertanyaan, misal "voucher"',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                if (entries.isEmpty)
                  const _EmptySearch()
                else
                  for (final category in _categories) ...[
                    if (entries.any((entry) => entry.category == category)) ...[
                      _categoryTitle(category),
                      _faqGroup(
                        entries
                            .where((entry) => entry.category == category)
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.violetSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppTheme.violet,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Belum menemukan jawaban? Hubungi organizer event '
                          'terkait atau pengelola EventKuy saat jam kerja.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.55,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _faqGroup(List<_FaqEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              ExpansionTile(
                key: ValueKey('faq-tile-${entries[i].question}'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: AppTheme.violet,
                collapsedIconColor: AppTheme.textFaint,
                title: Text(
                  entries[i].question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1.4,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entries[i].answer,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('faq-empty'),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppTheme.textFaint,
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada pertanyaan yang cocok',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci lain, misalnya "tiket" atau "password".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _FaqEntry {
  const _FaqEntry(this.category, this.question, this.answer);

  final String category;
  final String question;
  final String answer;
}

const _categories = ['Pembelian', 'Tiket & Check-in', 'Akun'];

const _faqEntries = <_FaqEntry>[
  _FaqEntry(
    'Pembelian',
    'Bagaimana cara membeli tiket?',
    'Pilih event di Beranda atau Jelajahi, buka detail event, tentukan jumlah '
        'tiket, lalu tekan "Daftar & Beli Tiket". Pilih metode pembayaran dan '
        'selesaikan checkout.',
  ),
  _FaqEntry(
    'Pembelian',
    'Apakah saya bisa membeli lebih dari satu tiket?',
    'Bisa. Di halaman checkout kamu dapat memilih jumlah tiket selama stok '
        'masih tersedia. Jumlah tiket dibatasi oleh sisa kuota event.',
  ),
  _FaqEntry(
    'Pembelian',
    'Bagaimana cara memakai kode voucher?',
    'Masukkan kode voucher di halaman checkout sebelum membayar. Voucher yang '
        'aktif akan memotong total pembayaran. Satu kode hanya bisa dipakai '
        'sekali per akun.',
  ),
  _FaqEntry(
    'Pembelian',
    'Metode pembayaran apa saja yang didukung?',
    'Checkout EventKuy saat ini adalah simulasi. Kamu bisa memilih metode '
        'seperti GoPay, OVO, dan Virtual Account saat menyelesaikan pesanan.',
  ),
  _FaqEntry(
    'Tiket & Check-in',
    'Di mana saya bisa melihat e-tiket?',
    'Buka tab Tiket. Semua tiket yang sudah dibeli tampil beserta kode unik '
        'dan statusnya.',
  ),
  _FaqEntry(
    'Tiket & Check-in',
    'Bagaimana cara mengunduh tiket PDF?',
    'Buka detail tiket lalu tekan tombol unduh. File PDF berisi QR code yang '
        'bisa ditunjukkan saat masuk event.',
  ),
  _FaqEntry(
    'Tiket & Check-in',
    'Bagaimana proses check-in di lokasi event?',
    'Tunjukkan QR code pada e-tiket kepada organizer. Organizer akan memindai '
        'QR tersebut. Satu tiket hanya bisa check-in satu kali.',
  ),
  _FaqEntry(
    'Tiket & Check-in',
    'Mengapa tiket saya berstatus check-in?',
    'Status check-in berarti tiket sudah dipindai oleh organizer di lokasi '
        'event. Tiket dengan status ini tidak bisa dipakai lagi.',
  ),
  _FaqEntry(
    'Akun',
    'Bagaimana cara mengubah nama atau foto profil?',
    'Buka tab Profil, pilih Edit Informasi Profil, ubah nama atau foto, lalu '
        'tekan Simpan Perubahan.',
  ),
  _FaqEntry(
    'Akun',
    'Bagaimana cara mengganti password?',
    'Buka Profil → Pengaturan → Ganti Password. Masukkan password lama, '
        'password baru, dan konfirmasi password baru.',
  ),
  _FaqEntry(
    'Akun',
    'Apakah saya bisa menjadi organizer?',
    'Peran organizer diatur oleh admin melalui dashboard Supabase. Hubungi '
        'pengelola EventKuy untuk mengajukan akun organizer.',
  ),
];
