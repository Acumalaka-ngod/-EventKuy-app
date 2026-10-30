import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/event_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/event_card.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final events = context.watch<EventProvider>().events;
    final list = events.where((e) => fav.onShelf(e.id)).toList();
    final activeCount = list.where((e) => fav.isFav(e.id)).length;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final columns = eventGridColumns(w);
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
                                'Event Tersimpan',
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
                  if (list.isEmpty)
                    Expanded(child: _buildEmptyState(context))
                  else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$activeCount Event Disimpan',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => fav.clearFavorites(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text(
                              'Hapus Semua',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(hPadding, 2, hPadding, 40),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: eventGridAspect(w),
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => EventGridCard(
                          event: list[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: list[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              child: const Icon(
                Icons.favorite_rounded,
                size: 50,
                color: AppTheme.violet,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Belum Ada Favorit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Simpan event yang kamu sukai agar tidak ketinggalan informasi terbarunya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 1)),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.explore_rounded, size: 20),
              label: const Text('Jelajahi Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(220, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
