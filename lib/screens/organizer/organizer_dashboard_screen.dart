import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';
import '../event/event_detail_screen.dart';
import '../scan/scan_screen.dart';

/// Dashboard Event Organizer — sesuai desain baru:
/// kartu event dengan badge status, statistik peserta/check-in/terjual,
/// dan daftar menu "Kelola Event".
class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final events = context.watch<EventProvider>().events;
    final event = events.isNotEmpty ? events.first : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: 860,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Header: logo + avatar
              Row(
                children: [
                  const AjanginLogo(markSize: 24, fontSize: 14.5),
                  const Spacer(),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Dashboard Event Organizer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),

              if (event != null) ...[
                _buildEventCard(event),
                const SizedBox(height: 16),
                _buildStatsRow(event),
                const SizedBox(height: 22),
                const Text(
                  'Kelola Event',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildManageList(context, event),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          EventImage(
            imageUrl: event.imageUrl,
            eventId: event.id,
            height: 64,
            width: 64,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTanggal(event.date)} • ${venueOf(event.location)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Sedang Berlangsung',
                    style: TextStyle(
                      color: AppTheme.accentEmerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Event event) {
    final sold = event.quota;
    final attendees = (event.quota * 1.083).round();
    final checkedIn = (event.quota * 0.947).round();

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.groups_rounded,
          color: AppTheme.primary,
          value: attendees,
          label: 'Total Peserta',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          color: AppTheme.accentEmerald,
          value: checkedIn,
          label: 'Check-in',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.confirmation_number_rounded,
          color: AppTheme.accentAmber,
          value: sold,
          label: 'Tiket Terjual',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    final text = value >= 1000
        ? '${(value ~/ 1000)}.${(value % 1000).toString().padLeft(3, '0')}'
        : '$value';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageList(BuildContext context, Event event) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.event_note_rounded,
            color: AppTheme.primary,
            title: 'Detail Event',
            subtitle: 'Ubah informasi event',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event),
              ),
            ),
          ),
          const Divider(height: 1, indent: 66),
          _buildMenuTile(
            icon: Icons.groups_rounded,
            color: const Color(0xFF2563EB),
            title: 'Peserta',
            subtitle: 'Lihat & kelola data peserta',
            onTap: () => _comingSoon(context, 'Kelola peserta'),
          ),
          const Divider(height: 1, indent: 66),
          _buildMenuTile(
            icon: Icons.confirmation_number_rounded,
            color: AppTheme.accentAmber,
            title: 'Tiket',
            subtitle: 'Kelola tiket & kuota',
            onTap: () => _comingSoon(context, 'Kelola tiket & kuota'),
          ),
          const Divider(height: 1, indent: 66),
          _buildMenuTile(
            icon: Icons.bar_chart_rounded,
            color: AppTheme.accentEmerald,
            title: 'Laporan',
            subtitle: 'Lihat ringkasan event',
            onTap: () => _comingSoon(context, 'Laporan event'),
          ),
          const Divider(height: 1, indent: 66),
          _buildMenuTile(
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFF7C3AED),
            title: 'Scan QR Check-in',
            subtitle: 'Buka mode panitia',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan hadir di Fase Berikutnya.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 19,
        color: AppTheme.textGrey,
      ),
    );
  }
}
