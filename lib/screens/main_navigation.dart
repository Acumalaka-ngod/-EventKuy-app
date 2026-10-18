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
/// - Mobile (<600)      : Bottom Navigation Bar
/// - Tablet (600-1024)  : Navigation Rail
/// - Desktop (>1024)    : Sidebar penuh 240px
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
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
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

  void _onTap(int i) => setState(() => _index = i);

  int _badgeFor(int index, int ticketCount, int favCount) {
    if (index == 2) return ticketCount;
    if (index == 3) return favCount;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(),
      tablet: _buildTablet(),
      desktop: _buildDesktop(),
    );
  }

  Widget _body() => IndexedStack(index: _index, children: _pages);

  // ==================== MOBILE (< 600px) ====================
  Widget _buildMobile() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

    return Scaffold(
      body: _body(),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _buildNavItem(
                      index: i,
                      icon: _items[i].icon,
                      activeIcon: _items[i].activeIcon,
                      label: _items[i].label,
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _index == index;

    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBadgeIcon(
            icon: isSelected ? activeIcon : icon,
            count: badgeCount,
            color: isSelected ? AppTheme.primary : AppTheme.textGrey,
            size: 23,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primary : AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TABLET (600 - 1024px) ====================
  Widget _buildTablet() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: _onTap,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primaryLight,
            selectedIconTheme: const IconThemeData(color: AppTheme.primary),
            unselectedIconTheme: const IconThemeData(color: AppTheme.textGrey),
            selectedLabelTextStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: AjanginMark(size: 30),
            ),
            destinations: [
              for (var i = 0; i < _items.length; i++)
                NavigationRailDestination(
                  icon: _buildBadgeIcon(
                    icon: _items[i].icon,
                    count: _badgeFor(i, ticketCount, favCount),
                    color: AppTheme.textGrey,
                    size: 22,
                  ),
                  selectedIcon: _buildBadgeIcon(
                    icon: _items[i].activeIcon,
                    count: _badgeFor(i, ticketCount, favCount),
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  label: Text(_items[i].label),
                ),
            ],
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppTheme.border,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  // ==================== DESKTOP (> 1024px) ====================
  Widget _buildDesktop() {
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: AjanginLogo(markSize: 28, fontSize: 15.5),
                ),
                for (var i = 0; i < _items.length; i++)
                  _buildSideItem(i, _badgeFor(i, ticketCount, favCount)),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'AjangIn v1.0.0 • Temukan. Ikuti. Hadiri.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppTheme.border,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 22,
                  color: active ? AppTheme.primary : AppTheme.textGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppTheme.primary : AppTheme.textDark,
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
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
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
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
