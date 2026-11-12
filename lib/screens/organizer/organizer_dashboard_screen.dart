import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/event_status.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';
import '../scan/scan_screen.dart';
import 'organizer_event_editor_screen.dart';

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
  String? _loadedEventsKey;
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
              if (mounted) _loadStats();
            })
            .catchError((_) {});
      } else {
        _loadStats();
      }
    });
  }

  /// Statistik dihitung dari seluruh event milik organizer yang login.
  Future<void> _loadStats({bool force = false}) async {
    if (!mounted) return;

    final user = context.read<AuthProvider>().user;
    final myEvents = _eventsForUser(
      user?.id,
      context.read<EventProvider>().events,
    );
    if (myEvents.isEmpty) {
      if (_loadedEventsKey != null) {
        setState(() {
          _eventTickets = const [];
          _loadedEventsKey = null;
          _loadingStats = false;
        });
      }
      return;
    }

    final key = _eventsKey(myEvents);
    if (!force && _loadedEventsKey == key) return;

    setState(() => _loadingStats = true);
    final tickets = <Ticket>[];
    try {
      final provider = context.read<TicketProvider>();
      for (final event in myEvents) {
        try {
          tickets.addAll(await provider.ticketsForEvent(event.id));
        } catch (_) {
          // Satu event gagal dimuat tidak boleh mengosongkan statistik
          // event lainnya.
        }
      }
      if (!mounted) return;
      setState(() {
        _eventTickets = tickets;
        _loadedEventsKey = key;
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
  /// Saat `userId` null (mis. widget test), pakai event pertama sebagai
  /// fallback agar dashboard tetap bisa dirender tanpa sesi.
  List<Event> _eventsForUser(String? userId, List<Event> events) {
    if (userId == null) {
      return events.isEmpty ? const [] : [events.first];
    }
    return events.where((event) => event.organizerId == userId).toList();
  }

  String _eventsKey(List<Event> events) =>
      events.map((event) => event.id).join(',');

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
    final myEvents = _eventsForUser(user?.id, eventProvider.events);

    if (myEvents.isNotEmpty &&
        _loadedEventsKey != _eventsKey(myEvents) &&
        !_loadingStats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadStats();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: 860,
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              await eventProvider.loadEvents(force: true);
              if (!mounted) return;
              await _loadStats(force: true);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 6),
                const Text(
                  'Kelola event yang kamu selenggarakan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 18),

                if (myEvents.isNotEmpty) ...[
                  _buildStatsRow(),
                  const SizedBox(height: 22),
                  _buildEventListHeader(myEvents.length),
                  const SizedBox(height: 10),
                  ...myEvents.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildEventCard(
                        event,
                        onTap: () => _openEditor(event),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  _buildManageList(context),
                ] else if (!eventProvider.loading) ...[
                  _buildNoEvent(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor([Event? event]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerEventEditorScreen(event: event),
      ),
    );
    if (!mounted || saved != true) return;

    final events = context.read<EventProvider>();
    await events.loadEvents(force: true);
    if (!mounted) return;
    await _loadStats(force: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event == null
              ? 'Event berhasil dibuat.'
              : 'Event berhasil diperbarui.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEventListHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Event Saya ($count)',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -0.2,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _openEditor,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Buat Event Baru'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: AppTheme.primary,
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 38,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada event yang dikelola',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buat event pertamamu dari aplikasi. Poster, jadwal, lokasi, '
            'harga, dan kuota bisa diatur sendiri.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Buat Event Baru',
            icon: Icons.add_rounded,
            onPressed: _openEditor,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      '${formatTanggal(event.date)} • '
                      '${venueOf(event.location)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _buildStatusBadge(event.date),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DateTime date) {
    final status = eventStatusFor(date);
    final color = switch (status) {
      EventStatus.upcoming => AppTheme.primary,
      EventStatus.today => AppTheme.accentEmerald,
      EventStatus.finished => AppTheme.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final sold = _eventTickets
        .where((t) => t.status == 'paid' || t.status == 'checked_in')
        .length;
    final attendees = sold;
    final checkedIn = _eventTickets
        .where((t) => t.status == 'checked_in')
        .length;

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
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageList(BuildContext context) {
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
              _loadStats(force: true);
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
