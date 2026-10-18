import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/event_card.dart';
import '../event/event_detail_screen.dart';

/// Layar Jelajahi Event — sesuai desain baru:
/// search, baris chip kategori, baris filter (Terbaru/Terpopuler/Lokasi),
/// daftar kartu event. Grid di layar lebar.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _sort = 'Terbaru';
  String? _city;

  static const _cities = ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta'];

  void _openDetail(Event e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Lokasi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public_rounded,
                  color: AppTheme.textMuted),
              title: const Text('Semua Kota'),
              trailing: _city == null
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _city = null);
                Navigator.pop(ctx);
              },
            ),
            for (final c in _cities)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_rounded,
                    color: AppTheme.primary),
                title: Text(c),
                trailing: _city == c
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() => _city = c);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();

    var events = provider.events;
    if (_city != null) {
      events = events
          .where((e) => cityOf(e.location).contains(_city!))
          .toList();
    }
    events = [...events];
    if (_sort == 'Terbaru') {
      events.sort((a, b) => a.date.compareTo(b.date));
    } else if (_sort == 'Terpopuler') {
      events.sort((a, b) => b.quota.compareTo(a.quota));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jelajahi Event'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isWide = w >= Breakpoints.mobile;
          final columns = eventGridColumns(w);

          return ConstrainedContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      contentPadding(w), 6, contentPadding(w), 12),
                  child: AppSearchBar(
                    hint: 'Cari event, kategori, atau lokasi...',
                    onChanged: provider.setQuery,
                  ),
                ),

                // Chip kategori
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: contentPadding(w)),
                    itemCount: EventProvider.categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = EventProvider.categories[i];
                      return CategoryChip(
                        label: c,
                        selected: provider.category == c,
                        onTap: () => provider.setCategory(c),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Chip filter: Terbaru / Terpopuler / Lokasi
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: contentPadding(w)),
                    children: [
                      CategoryChip(
                        label: 'Terbaru',
                        selected: _sort == 'Terbaru',
                        onTap: () => setState(() => _sort = 'Terbaru'),
                      ),
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: 'Terpopuler',
                        selected: _sort == 'Terpopuler',
                        onTap: () => setState(() => _sort = 'Terpopuler'),
                      ),
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: _city ?? 'Lokasi',
                        icon: Icons.keyboard_arrow_down_rounded,
                        selected: _city != null,
                        onTap: _showCityPicker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Daftar event
                Expanded(
                  child: provider.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primary,
                          ),
                        )
                      : events.isEmpty
                          ? _buildEmptyState(provider)
                          : isWide
                              ? GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                      contentPadding(w),
                                      2,
                                      contentPadding(w),
                                      24),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: eventGridAspect(w),
                                  ),
                                  itemCount: events.length,
                                  itemBuilder: (_, i) => EventGridCard(
                                    event: events[i],
                                    onTap: () => _openDetail(events[i]),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                      contentPadding(w),
                                      2,
                                      contentPadding(w),
                                      24),
                                  itemCount: events.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) => EventCard(
                                    event: events[i],
                                    onTap: () => _openDetail(events[i]),
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

  Widget _buildEmptyState(EventProvider provider) {
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
                Icons.search_off_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Event Ditemukan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba kata kunci lain, ganti kategori, atau pilih Semua Kota.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                provider.setCategory('Semua');
                provider.setQuery('');
                setState(() => _city = null);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Reset Pencarian'),
            ),
          ],
        ),
      ),
    );
  }
}
