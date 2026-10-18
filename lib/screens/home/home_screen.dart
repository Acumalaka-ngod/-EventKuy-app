import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/event_card.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/section_header.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';
import '../profile/profile_screen.dart';

/// Layar Beranda — sesuai desain baru:
/// header logo + bell + avatar, search, carousel hero, kategori ikon,
/// dan grid "Event Terdekat" (2 kolom di HP).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _catIcons = [
    (
      Icons.grid_view_rounded,
      'Semua',
      Color(0xFFEEF0FF),
      Color(0xFF4338CA)
    ),
    (
      Icons.music_note_rounded,
      'Konser',
      Color(0xFFF3E8FF),
      Color(0xFF7C3AED)
    ),
    (
      Icons.mic_rounded,
      'Seminar',
      Color(0xFFFFF7E6),
      Color(0xFFF59E0B)
    ),
    (
      Icons.palette_rounded,
      'Workshop',
      Color(0xFFFFEDD5),
      Color(0xFFF97316)
    ),
    (
      Icons.directions_run_rounded,
      'Olahraga',
      Color(0xFFDCFCE7),
      Color(0xFF16A34A)
    ),
  ];

  final _heroController = PageController(viewportFraction: 1);
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EventProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _openDetail(Event e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final user = context.watch<AuthProvider>().user;
    final heroes = provider.events.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: provider.loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final columns = eventGridColumns(w);
                  final heroHeight = w < Breakpoints.mobile
                      ? 206.0
                      : (w < Breakpoints.tablet ? 240.0 : 280.0);

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () async {
                      await context.read<EventProvider>().loadEvents();
                    },
                    child: ConstrainedContent(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentPadding(w),
                          vertical: 12,
                        ),
                        children: [
                          // === Header: logo, bell, avatar ===
                          Row(
                            children: [
                              const AjanginLogo(markSize: 26, fontSize: 15.5),
                              const Spacer(),
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppTheme.textDark,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Tidak ada notifikasi baru.'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    right: 11,
                                    top: 11,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileScreen()),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text(
                                    (user?.name.isNotEmpty ?? false)
                                        ? user!.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // === Search ===
                          AppSearchBar(
                            hint: 'Cari event, kategori, atau lokasi...',
                            onChanged: provider.setQuery,
                          ),
                          const SizedBox(height: 16),

                          // === Hero carousel ===
                          if (heroes.isNotEmpty) ...[
                            SizedBox(
                              height: heroHeight,
                              child: PageView.builder(
                                controller: _heroController,
                                onPageChanged: (i) =>
                                    setState(() => _heroIndex = i),
                                itemCount: heroes.length,
                                itemBuilder: (_, i) => HeroBanner(
                                  event: heroes[i],
                                  height: heroHeight,
                                  onTap: () => _openDetail(heroes[i]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Dots indikator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < heroes.length; i++)
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: i == _heroIndex ? 16 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _heroIndex
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],

                          // === Kategori ===
                          Row(
                            children: _catIcons.map((c) {
                              return Expanded(
                                child: CategoryIconItem(
                                  icon: c.$1,
                                  label: c.$2,
                                  bg: c.$3,
                                  iconColor: c.$4,
                                  selected: provider.category == c.$2,
                                  onTap: () => provider.setCategory(c.$2),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),

                          // === Event Terdekat ===
                          SectionHeader(
                            title: 'Event Terdekat',
                            onSeeAll: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainNavigation(
                                      initialIndex: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: eventGridAspect(w),
                            ),
                            itemCount: provider.nearby.length,
                            itemBuilder: (_, i) {
                              final e = provider.nearby[i];
                              return EventGridCard(
                                event: e,
                                onTap: () => _openDetail(e),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
