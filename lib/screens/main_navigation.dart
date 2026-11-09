import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/event.dart';
import '../providers/deep_link_provider.dart';
import '../providers/event_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_logo.dart';
import 'event/event_detail_screen.dart';
import 'explore/explore_screen.dart';
import 'favorite/favorite_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'ticket/my_tickets_screen.dart';

/// Navigasi utama 5 tab yang adaptif:
/// - Mobile (<720)       : bottom bar full-width
/// - Tablet (720-1100)   : rail ikon 96px
/// - Desktop (>1100)     : sidebar 240px
class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _handlePendingDeepLink();
    try {
      context.read<DeepLinkProvider>().addListener(_handlePendingDeepLink);
    } catch (_) {
      // DeepLinkProvider tidak terdaftar (mis. dalam beberapa widget test).
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePendingDeepLink();
  }

  @override
  void dispose() {
    try {
      context.read<DeepLinkProvider>().removeListener(_handlePendingDeepLink);
    } catch (_) {
      // DeepLinkProvider tidak terdaftar.
    }
    super.dispose();
  }

  /// Navigasi ke Detail Event bila ada deep link event yang menunggu.
  void _handlePendingDeepLink() {
    try {
      final provider = context.read<DeepLinkProvider>();
      final eventId = provider.pendingEventId;
      if (eventId == null) return;

      final events = context.read<EventProvider>().events;
      final Event? event = events.where((e) => e.id == eventId).firstOrNull;
      if (event == null) return;

      provider.takePending();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        ),
      );
    } catch (_) {
      // DeepLinkProvider atau EventProvider tidak tersedia.
    }
  }

  static const _pages = [
    HomeScreen(),
    ExploreScreen(),
    MyTicketsScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  static const _items = <({IconData icon, IconData activeIcon, String label})>[
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

  void _onTap(int i) {
    setState(() => _index = i);
  }

  int _badgeFor(int index, int ticketCount, int favCount) {
    if (index == 2) return ticketCount;
    if (index == 3) return favCount;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(),
      tablet: _buildRail(),
      desktop: _buildDesktop(),
    );
  }

  Widget _body() => IndexedStack(index: _index, children: _pages);

  // ==================== MOBILE (< 720px) ====================
  Widget _buildMobile() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      // Scaffold sudah menyisihkan tinggi bottomNavigationBar, jadi body tidak
      // perlu padding bawah tambahan.
      body: _body(),
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
            height: 78,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _buildMobileItem(
                      index: i,
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

  Widget _buildMobileItem({required int index, int badgeCount = 0}) {
    final item = _items[index];
    final isSelected = _index == index;

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
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.ink : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TABLET (720 - 1100px) ====================
  Widget _buildRail() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

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
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Semantics(
                      key: ValueKey('rail-item-$i'),
                      container: true,
                      button: true,
                      selected: _index == i,
                      label: _items[i].label,
                      onTap: () => _onTap(i),
                      child: ExcludeSemantics(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onTap(i),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: SizedBox(
                              width: 72,
                              height: 64,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildBadgeIcon(
                                    icon: _index == i
                                        ? _items[i].activeIcon
                                        : _items[i].icon,
                                    count: _badgeFor(i, ticketCount, favCount),
                                    color: _index == i
                                        ? AppTheme.ink
                                        : AppTheme.muted,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: _index == i
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _index == i
                                          ? AppTheme.ink
                                          : AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration: AppMotion.duration(
                                      context,
                                      const Duration(milliseconds: 180),
                                    ),
                                    height: 2,
                                    width: _index == i ? 14 : 0,
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
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  // ==================== DESKTOP (> 1100px) ====================
  Widget _buildDesktop() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

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
                for (var i = 0; i < _items.length; i++)
                  _buildSideItem(i, _badgeFor(i, ticketCount, favCount)),
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
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _buildSideItem(int index, int badgeCount) {
    final item = _items[index];
    final active = _index == index;

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

