import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/deep_link_provider.dart';
import '../providers/event_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_logo.dart';
import 'event/event_detail_screen.dart';
import 'explore/explore_screen.dart';
import 'favorite/favorite_screen.dart';
import 'home/home_screen.dart';
import 'organizer/organizer_dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'scan/scan_screen.dart';
import 'ticket/my_tickets_screen.dart';

typedef _NavItem = ({IconData icon, IconData activeIcon, String label});

/// Navigasi utama yang menyesuaikan peran akun:
/// - Pembeli   : 5 tab (Beranda, Jelajahi, Tiket, Favorit, Profil).
/// - Organizer : Beranda = dashboard, Scan QR besar di tengah, Profil.
///
/// Layout adaptif:
/// - Mobile (<720)       : bottom bar full-width
/// - Tablet (720-1100)   : rail ikon 96px
/// - Desktop (>1100)     : sidebar 240px
class MainNavigation extends StatefulWidget {
  final int initialIndex;

  /// Layar scan yang dibuka dari tombol Scan QR. Widget test dapat
  /// menginjeksi `ScanScreen(enableCamera: false)`.
  final Widget? scanScreen;

  const MainNavigation({super.key, this.initialIndex = 0, this.scanScreen});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _index;

  /// Dipakai dashboard organizer untuk memuat ulang statistik setelah
  /// kembali dari Scan QR check-in.
  final ValueNotifier<int> _organizerRefresh = ValueNotifier<int>(0);
  late final List<Widget> _organizerPages;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _organizerPages = [
      OrganizerDashboardScreen(refreshSignal: _organizerRefresh),
      const ProfileScreen(),
    ];
    _schedulePendingDeepLinkCheck();
    try {
      context.read<DeepLinkProvider>().addListener(
        _schedulePendingDeepLinkCheck,
      );
    } catch (_) {
      // DeepLinkProvider tidak terdaftar (mis. dalam beberapa widget test).
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePendingDeepLinkCheck();
  }

  @override
  void dispose() {
    try {
      context.read<DeepLinkProvider>().removeListener(
        _schedulePendingDeepLinkCheck,
      );
    } catch (_) {
      // DeepLinkProvider tidak terdaftar.
    }
    _organizerRefresh.dispose();
    super.dispose();
  }

  /// `takePending()` memanggil `notifyListeners()`, jadi pemeriksaan deep link
  /// tidak boleh berjalan di tengah fase build.
  void _schedulePendingDeepLinkCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handlePendingDeepLink();
    });
  }

  /// Navigasi ke Detail Event bila ada deep link event yang menunggu.
  ///
  /// Akun organizer tidak memiliki alur pembelian tiket, jadi deep link event
  /// tetap dikonsumsi tetapi tidak membuka halaman detail.
  void _handlePendingDeepLink() {
    try {
      final provider = context.read<DeepLinkProvider>();
      final eventId = provider.pendingEventId;
      if (eventId == null) return;

      final auth = context.read<AuthProvider>();
      if (auth.user?.isOrganizer == true) {
        provider.takePending();
        return;
      }

      final events = context.read<EventProvider>().events;
      final Event? event = events.where((e) => e.id == eventId).firstOrNull;
      if (event == null) return;

      provider.takePending();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      );
    } catch (_) {
      // Provider yang dibutuhkan tidak tersedia.
    }
  }

  static const _buyerPages = [
    HomeScreen(),
    ExploreScreen(),
    MyTicketsScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  static const _buyerItems = <_NavItem>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Jelajahi',
    ),
    (
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      label: 'Tiket',
    ),
    (
      icon: Icons.favorite_outline_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorit',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  /// Scan QR bukan halaman di IndexedStack — aksi ini membuka [ScanScreen]
  /// sebagai layar penuh. Karena itu hanya Beranda dan Profil yang menjadi tab.
  static const _organizerItems = <_NavItem>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  bool _isOrganizer(BuildContext context) =>
      context.watch<AuthProvider>().user?.isOrganizer == true;

  List<_NavItem> _itemsFor(bool isOrganizer) =>
      isOrganizer ? _organizerItems : _buyerItems;

  List<Widget> _pagesFor(bool isOrganizer) =>
      isOrganizer ? _organizerPages : _buyerPages;

  /// Indeks halaman yang aman saat peran akun berubah di tengah sesi.
  int _activeIndex(bool isOrganizer) {
    final pageCount = _pagesFor(isOrganizer).length;
    return _index >= pageCount ? 0 : _index;
  }

  void _onTap(int i) {
    // Saat masuk kembali ke tab Favorit, saring ulang daftarnya supaya
    // event yang sempat dilepas (salah pencet lalu dibiarkan) tidak menumpuk.
    if (i == 3 && _index != 3) {
      context.read<FavoriteProvider>().syncShelf();
    }
    setState(() => _index = i);
  }

  int _badgeFor(int index, int ticketCount, int favCount) {
    if (index == 2) return ticketCount;
    if (index == 3) return favCount;
    return 0;
  }

  Future<void> _openScan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.scanScreen ?? const ScanScreen(),
      ),
    );
    if (!mounted) return;
    // Check-in bisa mengubah jumlah peserta/check-in, jadi dashboard perlu
    // memuat ulang statistik saat organizer kembali.
    if (context.read<AuthProvider>().user?.isOrganizer == true) {
      _organizerRefresh.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrganizer = _isOrganizer(context);
    return ResponsiveLayout(
      mobile: _buildMobile(isOrganizer),
      tablet: _buildRail(isOrganizer),
      desktop: _buildDesktop(isOrganizer),
    );
  }

  Widget _body(bool isOrganizer) {
    final pages = _pagesFor(isOrganizer);
    return IndexedStack(index: _activeIndex(isOrganizer), children: pages);
  }

  // ==================== MOBILE (< 720px) ====================
  Widget _buildMobile(bool isOrganizer) {
    final ticketCount = isOrganizer
        ? 0
        : context.watch<TicketProvider>().tickets.length;
    final favCount = isOrganizer
        ? 0
        : context.watch<FavoriteProvider>().ids.length;
    final items = _itemsFor(isOrganizer);
    final activeIndex = _activeIndex(isOrganizer);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      // Scaffold sudah menyisihkan tinggi bottomNavigationBar, jadi body tidak
      // perlu padding bawah tambahan.
      body: _body(isOrganizer),
      // Bar menempel penuh ke tepi kiri/kanan layar. Border hanya di sisi atas
      // agar tidak terlihat terpotong, dan SafeArea menjaga gesture bar HP.
      bottomNavigationBar: Container(
        key: const ValueKey('mobile-nav-bar'),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: isOrganizer ? 84 : 78,
            child: Row(
              children: isOrganizer
                  ? [
                      Expanded(
                        child: _buildMobileItem(
                          items: items,
                          index: 0,
                          activeIndex: activeIndex,
                        ),
                      ),
                      _buildScanActionMobile(),
                      Expanded(
                        child: _buildMobileItem(
                          items: items,
                          index: 1,
                          activeIndex: activeIndex,
                        ),
                      ),
                    ]
                  : [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _buildMobileItem(
                            items: items,
                            index: i,
                            activeIndex: activeIndex,
                            badgeCount: _badgeFor(i, ticketCount, favCount),
                          ),
                        ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileItem({
    required List<_NavItem> items,
    required int index,
    required int activeIndex,
    int badgeCount = 0,
  }) {
    final item = items[index];
    final isSelected = activeIndex == index;

    return Semantics(
      key: ValueKey('mobile-nav-item-$index'),
      container: true,
      button: true,
      selected: isSelected,
      label: item.label,
      onTap: () => _onTap(index),
      child: ExcludeSemantics(
        child: InkWell(
          // Semua layout harus lewat `_onTap` supaya perilaku tab sama di HP,
          // tablet, dan desktop.
          onTap: () => _onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadgeIcon(
                icon: isSelected ? item.activeIcon : item.icon,
                count: badgeCount,
                color: isSelected ? AppTheme.ink : AppTheme.muted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.ink : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aksi Scan QR besar di tengah navbar mobile organizer.
  Widget _buildScanActionMobile() {
    return Semantics(
      key: const ValueKey('organizer-scan-action'),
      container: true,
      button: true,
      label: 'Scan QR',
      hint: 'Buka pemindai QR check-in',
      onTap: _openScan,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: _openScan,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 104,
            height: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.violet,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Scan QR',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TABLET (720 - 1100px) ====================
  Widget _buildRail(bool isOrganizer) {
    final ticketCount = isOrganizer
        ? 0
        : context.watch<TicketProvider>().tickets.length;
    final favCount = isOrganizer
        ? 0
        : context.watch<FavoriteProvider>().ids.length;
    final items = _itemsFor(isOrganizer);
    final activeIndex = _activeIndex(isOrganizer);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Row(
        children: [
          Container(
            width: 96,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 26, 0, 28),
                  child: EventKuyMark(size: 32),
                ),
                for (var i = 0; i < items.length; i++) ...[
                  // Aksi scan ditempatkan di antara Beranda dan Profil agar
                  // posisinya konsisten dengan navbar mobile.
                  if (isOrganizer && i == 1) _buildScanActionRail(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildRailItem(
                      items: items,
                      index: i,
                      activeIndex: activeIndex,
                      badgeCount: _badgeFor(i, ticketCount, favCount),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _body(isOrganizer)),
        ],
      ),
    );
  }

  Widget _buildRailItem({
    required List<_NavItem> items,
    required int index,
    required int activeIndex,
    int badgeCount = 0,
  }) {
    final item = items[index];
    final isSelected = activeIndex == index;

    return Semantics(
      key: ValueKey('rail-item-$index'),
      container: true,
      button: true,
      selected: isSelected,
      label: item.label,
      onTap: () => _onTap(index),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onTap(index),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: SizedBox(
              width: 72,
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadgeIcon(
                    icon: isSelected ? item.activeIcon : item.icon,
                    count: badgeCount,
                    color: isSelected ? AppTheme.ink : AppTheme.muted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? AppTheme.ink : AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: AppMotion.duration(
                      context,
                      const Duration(milliseconds: 180),
                    ),
                    height: 2,
                    width: isSelected ? 14 : 0,
                    decoration: BoxDecoration(
                      color: AppTheme.violet,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Aksi Scan QR menonjol pada rail tablet organizer.
  Widget _buildScanActionRail() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        key: const ValueKey('organizer-scan-action'),
        container: true,
        button: true,
        label: 'Scan QR',
        hint: 'Buka pemindai QR check-in',
        onTap: _openScan,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openScan,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: SizedBox(
                width: 72,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.violet,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan QR',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP (> 1100px) ====================
  Widget _buildDesktop(bool isOrganizer) {
    final ticketCount = isOrganizer
        ? 0
        : context.watch<TicketProvider>().tickets.length;
    final favCount = isOrganizer
        ? 0
        : context.watch<FavoriteProvider>().ids.length;
    final items = _itemsFor(isOrganizer);
    final activeIndex = _activeIndex(isOrganizer);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 32, 22, 26),
                  child: EventKuyLogo(markSize: 30, fontSize: 17),
                ),
                for (var i = 0; i < items.length; i++) ...[
                  if (isOrganizer && i == 1) _buildScanActionDesktop(),
                  _buildSideItem(
                    items: items,
                    index: i,
                    activeIndex: activeIndex,
                    badgeCount: _badgeFor(i, ticketCount, favCount),
                  ),
                ],
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(32, 16, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EventKuy v1.0.0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textFaint,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Temukan. Ikuti. Hadiri.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(isOrganizer)),
        ],
      ),
    );
  }

  Widget _buildSideItem({
    required List<_NavItem> items,
    required int index,
    required int activeIndex,
    int badgeCount = 0,
  }) {
    final item = items[index];
    final active = activeIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
      child: Material(
        color: active ? AppTheme.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: () => _onTap(index),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 21,
                  color: active ? Colors.white : AppTheme.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? Colors.white : AppTheme.muted,
                    ),
                  ),
                ),
                if (badgeCount > 0) _badgeChip(badgeCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol Scan QR penuh pada sidebar desktop organizer.
  Widget _buildScanActionDesktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
      child: Semantics(
        key: const ValueKey('organizer-scan-action'),
        container: true,
        button: true,
        label: 'Scan QR',
        hint: 'Buka pemindai QR check-in',
        onTap: _openScan,
        child: ExcludeSemantics(
          child: Material(
            color: AppTheme.violet,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InkWell(
              onTap: _openScan,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan QR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WIDGET BANTUAN ====================
  Widget _buildBadgeIcon({
    required IconData icon,
    required int count,
    required Color color,
    required double size,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: size),
        if (count > 0)
          Positioned(
            top: -7,
            right: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _badgeChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.coral,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
