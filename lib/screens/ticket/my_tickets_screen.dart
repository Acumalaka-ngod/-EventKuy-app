import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/event_card.dart';
import '../../widgets/ticket_item.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';

/// Layar Tiket Saya — sesuai desain baru:
/// kartu e-tiket bergradien dengan QR, 1/2/3 kolom menyesuaikan lebar.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  String _activeTab = 'Semua';

  @override
  Widget build(BuildContext context) {
    final allTickets = context.watch<TicketProvider>().tickets;
    final user = context.watch<AuthProvider>().user;
    final events = context.watch<EventProvider>().events;

    final filteredTickets = allTickets.where((t) {
      if (_activeTab == 'Aktif') {
        return t.status.toLowerCase() != 'checked_in';
      }
      if (_activeTab == 'Selesai') {
        return t.status.toLowerCase() == 'checked_in';
      }
      return true;
    }).toList();

    Event? eventFor(int id) {
      for (final e in events) {
        if (e.id == id) return e;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tiket Saya'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: Column(
        children: [
          // Segmented filter
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.field,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Semua', allTickets.length),
                      _buildTab(
                          'Aktif',
                          allTickets
                              .where((t) =>
                                  t.status.toLowerCase() != 'checked_in')
                              .length),
                      _buildTab(
                          'Selesai',
                          allTickets
                              .where((t) =>
                                  t.status.toLowerCase() == 'checked_in')
                              .length),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Daftar tiket
          Expanded(
            child: filteredTickets.isEmpty
                ? _buildEmptyState(context)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = (constraints.maxWidth < 1240
                              ? constraints.maxWidth
                              : 1240.0) -
                          40;
                      final columns = maxW < 620 ? 1 : (maxW < 1100 ? 2 : 3);
                      final cardWidth =
                          (maxW - (columns - 1) * 20) / columns;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 1200),
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                for (final t in filteredTickets)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _buildTicketCard(
                                        context, t, user?.name, eventFor),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Ticket t,
    String? userName,
    Event? Function(int) eventFor,
  ) {
    final ev = eventFor(t.eventId);
    final dateLocation = ev == null
        ? ''
        : '${formatTanggal(ev.date)} • ${venueOf(ev.location)}';

    return TicketItem(
      ticket: t,
      dateLocation: dateLocation,
      attendeeName: userName ?? 'Andi Pratama',
      onViewDetail: ev == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: ev),
                ),
              ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _activeTab == 'Semua'
                  ? 'Belum Ada Tiket Terdaftar'
                  : 'Tidak ada tiket di tab $_activeTab',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jelajahi konser musik, seminar, atau workshop seru dan amankan tiketmu sekarang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(initialIndex: 0),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Cari Event Sekarang'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final isSelected = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color:
                      isSelected ? AppTheme.textDark : AppTheme.textMuted,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
