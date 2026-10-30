import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/favorite_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_logo.dart';
import 'explore/explore_screen.dart';
import 'favorite/favorite_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'ticket/my_tickets_screen.dart';

/// Navigasi utama 5 tab yang adaptif:
/// - Mobile (<720)       : floating bottom bar
/// - Tablet (720-1100)   : rail ikon 88px
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
      label: 'Beranda'
    ),
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Jelajahi'
    ),
    (
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      label: 'Tiket'
    ),
    (
      icon: Icons.favorite_outline_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorit'
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil'
    ),
  ];

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
      // perlu padding bawah tambahan (dulu 84px -> muncul pita kosong di atas
      // navbar yang menutupi konten).
      body: _body(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
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

    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBadgeIcon(
            icon: isSelected ? item.activeIcon : item.icon,
            count: badgeCount,
            color: isSelected ? AppTheme.ink : AppTheme.muted,
            size: 19,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.ink : AppTheme.muted,
            ),
          ),
        ],
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
            width: 88,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppTheme.border),
              ),
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
                    child: Tooltip(
                      message: _items[i].label,
                      child: InkWell(
                        onTap: () => _onTap(i),
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 58,
                          height: 50,
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
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
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
              border: Border(
                right: BorderSide(color: AppTheme.border),
              ),
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
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _onTap(index),
          borderRadius: BorderRadius.circular(6),
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
                borderRadius: BorderRadius.circular(9),
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
        borderRadius: BorderRadius.circular(20),
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
