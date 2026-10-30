import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/event_card.dart';
import '../../widgets/ticket_item.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with WidgetsBindingObserver {
  String _activeTab = 'Semua';
  TicketProvider? _tickets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final events = context.read<EventProvider>();
      if (events.events.isEmpty) events.loadEvents();

      final tickets = context.read<TicketProvider>();
      _tickets = tickets;
      tickets.addListener(_onTicketsChanged);
      tickets.startWatching();
      if (tickets.tickets.isEmpty) {
        tickets.load().catchError((_) {});
      } else {
        tickets.refresh();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickets?.removeListener(_onTicketsChanged);
    _tickets?.stopWatching();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat aplikasi kembali aktif, tarik data terbaru (jaga-jaga bila
    // koneksi realtime sempat terputus ketika aplikasi di latar belakang).
    if (state == AppLifecycleState.resumed) {
      _tickets?.refresh();
    }
  }

  /// Tampilkan notifikasi ketika tiket baru saja berubah menjadi checked_in
  /// (mis. organizer baru saja scan QR di perangkat lain).
  void _onTicketsChanged() {
    final tickets = _tickets;
    final ticket = tickets?.lastCheckIn;
    if (tickets == null || ticket == null) return;
    tickets.acknowledgeCheckIn();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.ink,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check-in berhasil — ${ticket.code}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTickets = context.watch<TicketProvider>().tickets;
    final user = context.watch<AuthProvider>().user;
    final events = context.watch<EventProvider>().events;

    final activeCount = allTickets.where((t) => t.status.toLowerCase() != 'checked_in').length;
    final doneCount = allTickets.length - activeCount;

    final filteredTickets = allTickets.where((t) {
      if (_activeTab == 'Aktif') return t.status.toLowerCase() != 'checked_in';
      if (_activeTab == 'Selesai') return t.status.toLowerCase() == 'checked_in';
      return true;
    }).toList();

    Event? eventFor(String id) => events.where((e) => e.id == id).firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPadding = contentPadding(w);

            return ConstrainedContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              Text(
                                'Tiket & Pass Saya',
                                style: TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: w < Breakpoints.mobile ? 30 : 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: AppTheme.ink,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (Navigator.canPop(context))
                          _roundButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEFF5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTab('Semua', allTickets.length),
                              _buildTab('Aktif', activeCount),
                              _buildTab('Selesai', doneCount),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: filteredTickets.isEmpty
                        ? _buildEmptyState(context)
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(hPadding, 4, hPadding, 40),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: w < 640 ? 1 : (w < 1050 ? 2 : 3),
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              mainAxisExtent: 600 *
                                  MediaQuery.textScalerOf(context).scale(1),
                            ),
                            itemCount: filteredTickets.length,
                            itemBuilder: (context, i) {
                              final t = filteredTickets[i];
                              final ev = eventFor(t.eventId);
                              final dateLocation = ev == null
                                  ? ''
                                  : '${formatTanggal(ev.date)} · ${venueOf(ev.location)}';
                              
                              return TicketItem(
                                ticket: t,
                                dateLocation: dateLocation,
                                attendeeName: user?.name ?? 'Pengguna',
                                onCheckIn: () async {
                                  try {
                                    await context
                                        .read<TicketProvider>()
                                        .checkIn(t.code);
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(friendlyError(error)),
                                      ),
                                    );
                                  }
                                },
                                onViewDetail: ev == null ? null : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.ink, size: 22),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.confirmation_number_rounded, size: 50, color: AppTheme.violet),
            ),
            const SizedBox(height: 32),
            Text(
              _activeTab == 'Semua' ? 'Belum Ada Tiket' : 'Tidak ada tiket $_activeTab',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jelajahi berbagai event menarik dan amankan tiket pertamamu sekarang juga!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
                (_) => false,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(220, 54),
              ),
              child: const Text('Cari Event'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final isSelected = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x141E1946), blurRadius: 10, offset: Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.violet : AppTheme.muted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.violetSoft : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppTheme.violet : AppTheme.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
