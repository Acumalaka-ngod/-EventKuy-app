import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/favorite_provider.dart';
import '../../services/share_service.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_gallery.dart';
import '../checkout/checkout_screen.dart';

/// Detail event EventKuy — hero foto + tombol glass, chip kategori & rating,
/// info tanggal/lokasi, penyelenggara, tentang acara, dan buy bar di bawah.
class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = ShareService.shareText(widget.event);
    final result = await ShareService.share(text);
    if (!mounted) return;

    switch (result) {
      case ShareResult.shared:
        messenger.showSnackBar(
          const SnackBar(content: Text('Event dibagikan lewat share sheet!')),
        );
      case ShareResult.copied:
        messenger.showSnackBar(
          const SnackBar(content: Text('Info event disalin ke clipboard!')),
        );
      case ShareResult.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gagal membagikan event. Coba lagi.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final isFav = fav.isFav(widget.event.id);
    final event = widget.event;
    final tagline = event.tags.take(2).join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final compact = w < Breakpoints.mobile;
          final heroHeight = compact
              ? (h * 0.44).clamp(340.0, 520.0).toDouble()
              : (h * 0.57).clamp(340.0, 590.0).toDouble();

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: compact ? 24 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: heroHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EventGallery(
                        images: event.galleryImages,
                        eventId: event.id,
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 18 : 28,
                            20,
                            compact ? 18 : 28,
                            0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _glassButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'Kembali',
                                onTap: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  _glassButton(
                                    icon: Icons.ios_share_rounded,
                                    label: 'Bagikan event',
                                    onTap: _share,
                                  ),
                                  const SizedBox(width: 12),
                                  _glassButton(
                                    icon: Icons.favorite_border_rounded,
                                    selectedIcon: Icons.favorite_rounded,
                                    label: 'Simpan ke favorit',
                                    selectedLabel: 'Hapus dari favorit',
                                    onTap: () => fav.toggle(event.id),
                                    active: isFav,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 18 : 28,
                        compact ? 25 : 34,
                        compact ? 18 : 28,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.violetSoft,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  event.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.violet,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (event.ratingCount > 0) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.amber,
                                  size: 17,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppTheme.amber,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '(${event.ratingCount} ulasan)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Belum ada ulasan',
                                  style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            event.title,
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: compact ? 35 : 52,
                              fontWeight: FontWeight.w800,
                              letterSpacing: compact ? -1.5 : -2.6,
                              height: 1.08,
                              color: AppTheme.ink,
                            ),
                          ),
                          if (tagline.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              tagline,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          _infoCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'TANGGAL & WAKTU',
                            title: formatTanggal(event.date),
                            subtitle: '${event.timeRange} WIB',
                          ),
                          const SizedBox(height: 12),
                          _infoCard(
                            icon: Icons.location_on_rounded,
                            label: 'LOKASI',
                            title: venueOf(event.location),
                            subtitle: event.location,
                          ),
                          const SizedBox(height: 26),
                          _buildOrganizer(context),
                          const SizedBox(height: 30),
                          const Text(
                            'Tentang Acara',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppTheme.muted,
                              height: 1.7,
                            ),
                          ),
                          if (event.tags.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: event.tags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F0F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        key: const ValueKey('event-detail-buy-bar'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Tiket',
                        style: TextStyle(color: AppTheme.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRp(event.price),
                        style: const TextStyle(
                          fontFamily: AppTheme.headingFont,
                          color: AppTheme.violetDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      if (event.available != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.isSoldOut
                              ? 'Tiket habis'
                              : 'Sisa ${event.available} tiket',
                          style: TextStyle(
                            color: event.isSoldOut ? AppTheme.red : AppTheme.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: CustomButton(
                      label: event.isSoldOut ? 'Tiket Habis' : 'Daftar & Beli Tiket',
                      height: 56,
                      onPressed: event.isSoldOut
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(event: event),
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    IconData? selectedIcon,
    String? selectedLabel,
    bool active = false,
  }) {
    return AppIconButton(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      selectedLabel: selectedLabel,
      selected: active,
      onPressed: onTap,
      backgroundColor: const Color(0x33000000),
      foregroundColor: Colors.white,
      selectedBackgroundColor: Colors.white,
      selectedForegroundColor: AppTheme.coral,
      borderColor: Colors.white.withValues(alpha: 0.2),
      iconSize: 20,
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.violetSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.violet, size: 21),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizer(BuildContext context) {
    final org = widget.event.organizer;
    final displayOrg =
        org != null && org.displayName.isNotEmpty ? org : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                displayOrg?.initial ?? 'E',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENYELENGGARA',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayOrg?.displayName ?? 'EventKuy Official',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (displayOrg != null && displayOrg.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayOrg.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (displayOrg != null && displayOrg.verified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.greenSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 12, color: AppTheme.green),
                  SizedBox(width: 4),
                  Text(
                    'Terverifikasi',
                    style: TextStyle(
                      color: AppTheme.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
