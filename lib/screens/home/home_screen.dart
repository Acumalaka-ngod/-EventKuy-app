import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_provider.dart';
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

  final _heroController = PageController(viewportFraction: 1);
  final _searchController = TextEditingController();
  EventProvider? _eventProvider;
  int _heroIndex = 0;
  String _city = 'Semua Kota';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EventProvider>().loadEvents();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<EventProvider>();
    if (!identical(_eventProvider, provider)) {
      _eventProvider?.removeListener(_syncSearchField);
      _eventProvider = provider;
      _eventProvider!.addListener(_syncSearchField);
      _syncSearchField();
    }
  }

  void _syncSearchField() {
    final query = _eventProvider?.query ?? '';
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _eventProvider?.removeListener(_syncSearchField);
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _openDetail(Event e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
    );
  }

  /// Opsi kota diambil dari lokasi event yang benar-benar ada di backend,
  /// bukan daftar statis. "Semua Kota" selalu jadi pilihan pertama.
  List<String> _cityOptions(EventProvider provider) {
    final cities = <String>{};
    for (final event in provider.events) {
      final city = cityOf(event.location).trim();
      if (city.isNotEmpty) cities.add(city);
    }
    final sorted = cities.toList()..sort();
    return ['Semua Kota', ...sorted];
  }

  void _showCityPicker() {
    final cities = _cityOptions(context.read<EventProvider>());
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
                itemCount: cities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = cities[i];
                  final isSelected = _city == c;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _city = c;
                        _heroIndex = 0;
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                            color: isSelected
                                ? AppTheme.violet
                                : AppTheme.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.violetDark
                                    : AppTheme.ink,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.violet,
                              size: 20,
                            ),
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

  Future<void> _showNotifications() async {
    final provider = context.read<NotificationProvider>();
    await provider.load();
    if (!mounted) return;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              'Notifikasi',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (provider.notifications.isEmpty)
              Column(
                children: [
                  const Text(
                    'Pemberitahuan penting tentang tiket dan event akan muncul di sini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.violetSoft,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 42,
                        color: AppTheme.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Belum Ada Notifikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Belum ada pengumuman untukmu saat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )
            else
              Column(
                children: provider.notifications.map((n) {
                  return ListTile(
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: n.isRead ? AppTheme.textMuted : AppTheme.ink,
                      ),
                    ),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                    trailing: n.isRead
                        ? const Icon(
                            Icons.done,
                            size: 18,
                            color: AppTheme.muted,
                          )
                        : null,
                    onTap: () {
                      provider.markRead(n);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(minimumSize: const Size(160, 48)),
                child: const Text('Tutup'),
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
    final selected = _city.trim().toLowerCase();
    return list
        .where((e) => cityOf(e.location).trim().toLowerCase() == selected)
        .toList();
  }

  Widget _buildErrorState(EventProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: AppTheme.violet,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Event',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.error ?? 'Periksa koneksi internet lalu coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadEvents(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(EventProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.violetSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 38,
              color: AppTheme.violet,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Event Tidak Ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah kata kunci, kategori, atau kota.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.muted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              provider.setCategory('Semua');
              provider.setQuery('');
              setState(() => _city = 'Semua Kota');
            },
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name.isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'User';

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: provider.loading && provider.events.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.violet),
              )
            : provider.error != null && provider.events.isEmpty
            ? _buildErrorState(provider)
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
                    onRefresh: () => provider.loadEvents(force: true),
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
                            controller: _searchController,
                            onChanged: provider.setQuery,
                            onFilterTap: _showCityPicker,
                          ),
                          const SizedBox(height: 32),
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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < heroes.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: i == _heroIndex ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _heroIndex
                                          ? AppTheme.violet
                                          : AppTheme.border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                          _buildCategoryRow(w, provider),
                          const SizedBox(height: 36),
                          if (events.isEmpty)
                            _buildEmptyState(provider)
                          else ...[
                            SectionHeader(
                              title: 'Event Terdekat Untukmu',
                              subtitle: 'Pilihan event spesial di sekitarmu.',
                              onSeeAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigation(initialIndex: 1),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                          ],
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
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name[0].toUpperCase()
        : 'A';

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }

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
          label: 'Notifikasi',
          onTap: _showNotifications,
        ),
        const SizedBox(width: 6),
        Semantics(
          container: true,
          button: true,
          label: 'Buka profil',
          onTap: openProfile,
          child: ExcludeSemantics(
            child: IconButton(
              onPressed: openProfile,
              tooltip: 'Buka profil',
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                fixedSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              icon: Container(
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
          ),
        ),
      ],
    );
  }

  Widget _topbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppTheme.ink, size: 22),
          ),
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
        height: 48,
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
