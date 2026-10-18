import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/event_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/event_card.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';

/// Layar Favorit — Responsif:
/// - Mobile (<600)     : daftar vertikal (EventCard)
/// - Tablet/Desktop    : grid poster 3-4 kolom (EventGridCard)
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final events = context.watch<EventProvider>().events;
    final list = events.where((e) => fav.isFav(e.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Event Tersimpan'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isWide = w >= Breakpoints.mobile;
          final columns = eventGridColumns(w);

          if (list.isEmpty) return _buildEmptyState(context);

          return ConstrainedContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      contentPadding(w), 8, contentPadding(w), 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${list.length} Event Disimpan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          for (final e in list) {
                            fav.toggle(e.id);
                          }
                        },
                        child: const Text('Hapus Semua',
                            style: TextStyle(
                                color: AppTheme.secondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isWide
                      ? GridView.builder(
                          padding: EdgeInsets.fromLTRB(contentPadding(w), 8,
                              contentPadding(w), 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: eventGridAspect(w),
                          ),
                          itemCount: list.length,
                          itemBuilder: (_, i) => EventGridCard(
                            event: list[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailScreen(event: list[i]),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(contentPadding(w), 8,
                              contentPadding(w), 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EventCard(
                              event: list[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventDetailScreen(event: list[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
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
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 40,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Event Favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simpan event impianmu dengan menekan ikon bookmark atau hati di halaman Beranda & Jelajahi.',
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
                    builder: (_) => const MainNavigation(initialIndex: 1),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Jelajahi Event'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
