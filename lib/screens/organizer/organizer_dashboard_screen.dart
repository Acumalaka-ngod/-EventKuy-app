import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';
import '../event/event_detail_screen.dart';
import '../scan/scan_screen.dart';

/// Dashboard Event Organizer — sesuai desain baru:
/// kartu event dengan badge status, statistik peserta/check-in/terjual,
/// dan daftar menu "Kelola Event".
class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  List<Ticket> _eventTickets = const [];
  String? _loadedEventId;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = context.read<EventProvider>();
      if (events.events.isEmpty) {
        events
            .loadEvents()
            .then((_) {
              if (mounted) _loadStatsForFirstEvent();
            })
            .catchError((_) {});
      } else {
        _loadStatsForFirstEvent();
      }
    });
  }

  Future<void> _loadStatsForFirstEvent({bool force = false}) async {
    if (!mounted) return;

    final user = context.read<AuthProvider>().user;
    final events = context.read<EventProvider>().events;
    final event = _eventForUser(user?.id, events);
    if (event == null) {
      if (_loadedEventId != null) {
        setState(() {
          _eventTickets = const [];
          _loadedEventId = null;
          _loadingStats = false;
        });
      }
      return;
    }

    final eventId = event.id;
    if (!force && _loadedEventId == eventId) return;

    setState(() => _loadingStats = true);
    try {
      final tickets =
          await context.read<TicketProvider>().ticketsForEvent(eventId);
      if (!mounted) return;
      setState(() {
        _eventTickets = tickets;
        _loadedEventId = eventId;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventTickets = const [];
        _loadingStats = false;
      });
    }
  }

  /// Event yang ditampilkan harus milik organizer yang sedang login.
  /// Saat `userId` null (mis. widget test), pakai event pertama sebagai fallback.
  Event? _eventForUser(String? userId, List<Event> events) {
    if (events.isEmpty) return null;
    if (userId == null) return events.first;
    for (final event in events) {
      if (event.organizerId == userId) return event;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user != null && !user.isOrganizer) {
      return Scaffold(
        backgroundColor: AppTheme.canvas,
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya untuk akun organizer.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final eventProvider = context.watch<EventProvider>();
    final events = eventProvider.events;
    final event = _eventForUser(user?.id, events);

    if (event != null && _loadedEventId != event.id && !_loadingStats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadStatsForFirstEvent();
      });
    }

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
                  const EventKuyLogo(markSize: 24, fontSize: 14.5),
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
              ] else if (!eventProvider.loading) ...[
                _buildNoEvent(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoEvent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 38, color: AppTheme.textGrey),
          SizedBox(height: 12),
          Text(
            'Belum ada event yang dikelola',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hubungkan akun organizer ke event lewat SQL Editor, '
            'lalu buka kembali dashboard ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
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
    final sold = _eventTickets
        .where((t) => t.status == 'paid' || t.status == 'checked_in')
        .length;
    final attendees = sold;
    final checkedIn =
        _eventTickets.where((t) => t.status == 'checked_in').length;

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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
              if (!mounted) return;
              _loadStatsForFirstEvent(force: true);
            },
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
