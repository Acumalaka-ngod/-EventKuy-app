import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/event_card.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/section_header.dart';
import '../event/event_detail_screen.dart';
import '../main_navigation.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    'Semua',
    'Konser',
    'Seminar',
    'Workshop',
    'Olahraga',
  ];

  static const _cities = [
    'Semua Kota',
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
  ];

  final _heroController = PageController(viewportFraction: 1);
  int _heroIndex = 0;
  String _city = 'Jakarta';

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

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3DCCF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Lokasi',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan event seru di kota favoritmu.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _cities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = _cities[i];
                  final isSelected = _city == c;
                  return InkWell(
                    onTap: () {
                      setState(() => _city = c);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.violetSoft : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.violet : AppTheme.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: isSelected ? AppTheme.violet : AppTheme.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppTheme.violetDark : AppTheme.ink,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.violet, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Event> _visibleEvents(EventProvider provider) {
    final list = provider.events;
    if (_city == 'Semua Kota') return list;
    return list.where((e) => cityOf(e.location).toLowerCase().contains(_city.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name.isNotEmpty ?? false) ? user!.name.split(' ').first : 'User';

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final columns = eventGridColumns(w);
                  final events = _visibleEvents(provider);
                  final heroes = events.take(5).toList();
                  final heroHeight = w < Breakpoints.mobile
                      ? 400.0
                      : (w < Breakpoints.tablet ? 440.0 : 480.0);

                  return RefreshIndicator(
                    color: AppTheme.violet,
                    onRefresh: () async => await provider.loadEvents(),
                    child: ConstrainedContent(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentPadding(w),
                          vertical: 20,
                        ),
                        children: [
                          _buildTopbar(context, user),
                          const SizedBox(height: 28),
                          Text(
                            'Hai, $firstName!',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mau seru-seruan di mana hari ini?',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: w < Breakpoints.mobile ? 28 : 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.2,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppSearchBar(
                            hint: 'Cari event, kategori, atau lokasi...',
                            onChanged: provider.setQuery,
                            onFilterTap: _showCityPicker,
                          ),
                          const SizedBox(height: 32),
                          if (heroes.isNotEmpty) ...[
                            SizedBox(
                              height: heroHeight,
                              child: PageView.builder(
                                controller: _heroController,
                                onPageChanged: (i) => setState(() => _heroIndex = i),
                                itemCount: heroes.length,
                                itemBuilder: (_, i) => HeroBanner(
                                  event: heroes[i],
                                  height: heroHeight,
                                  onTap: () => _openDetail(heroes[i]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < heroes.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: i == _heroIndex ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _heroIndex ? AppTheme.violet : AppTheme.border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                          _buildCategoryRow(w, provider),
                          const SizedBox(height: 36),
                          SectionHeader(
                            title: 'Event Terdekat Untukmu',
                            subtitle: 'Pilihan event spesial di sekitarmu.',
                            onSeeAll: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainNavigation(initialIndex: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: eventGridAspect(w),
                            ),
                            itemCount: events.length,
                            itemBuilder: (_, i) => EventGridCard(
                              event: events[i],
                              onTap: () => _openDetail(events[i]),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTopbar(BuildContext context, AppUser? user) {
    final initial =
        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A';

    return Row(
      children: [
        GestureDetector(
          onTap: _showCityPicker,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(Icons.place_outlined, size: 15, color: AppTheme.muted),
              const SizedBox(width: 5),
              Text(
                _city == 'Semua Kota' ? 'Semua Kota' : '$_city, ID',
                style: const TextStyle(
                  fontFamily: AppTheme.headingFont,
                  color: AppTheme.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
        const Spacer(),
        _topbarAction(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
          hasBadge: true,
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topbarAction({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppTheme.ink, size: 22),
            if (hasBadge)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.violet,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(double width, EventProvider provider) {
    final items = [
      for (final c in _categories)
        CategoryIconItem(
          label: c,
          selected: provider.category == c,
          onTap: () => provider.setCategory(c),
        ),
    ];

    if (width < Breakpoints.mobile) {
      return SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 22),
          itemBuilder: (_, i) => items[i],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 30),
          items[i],
        ],
      ],
    );
  }
}
