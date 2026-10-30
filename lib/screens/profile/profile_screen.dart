import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/ticket_provider.dart';
import '../auth/login_screen.dart';
import '../organizer/organizer_dashboard_screen.dart';
import '../scan/scan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.redSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.red, size: 28),
            ),
            const SizedBox(height: 20),
            const Text(
              'Keluar dari EventKuy?',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kamu perlu masuk kembali untuk mengakses tiket dan event tersimpanmu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.6),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        context.read<FavoriteProvider>().clear();
                        context.read<TicketProvider>().clear();
                      }
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Ya, Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final ticketCount = context.watch<TicketProvider>().tickets.length;
    final favCount = context.watch<FavoriteProvider>().ids.length;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPadding = contentPadding(w);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 40),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              Text(
                                'Profil Saya',
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
                        _roundButton(
                          icon: Navigator.canPop(context) ? Icons.arrow_back_rounded : Icons.settings_rounded,
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengaturan akan hadir segera!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildProfileCard(user?.name, user?.email),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatCard('Tiket Saya', '$ticketCount', Icons.confirmation_number_rounded),
                        const SizedBox(width: 12),
                        _buildStatCard('Favorit', '$favCount', Icons.favorite_rounded),
                        const SizedBox(width: 12),
                        _buildStatCard('Poin', '1.250', Icons.stars_rounded),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildGroup(
                      title: 'AKUN & AKTIVITAS',
                      items: [
                        _MenuItem(icon: Icons.person_rounded, title: 'Edit Informasi Profil', onTap: () {}),
                        _MenuItem(icon: Icons.receipt_long_rounded, title: 'Riwayat Transaksi', onTap: () {}),
                        _MenuItem(icon: Icons.credit_card_rounded, title: 'Metode Pembayaran', onTap: () {}),
                      ],
                    ),
                    if (user?.isOrganizer == true) ...[
                      _buildGroup(
                        title: 'MODE ORGANIZER',
                        items: [
                          _MenuItem(
                            icon: Icons.dashboard_customize_rounded,
                            title: 'Dashboard Organizer',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrganizerDashboardScreen(),
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Scan QR Check-in',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScanScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    _buildGroup(
                      title: 'BANTUAN',
                      items: [
                        _MenuItem(icon: Icons.help_outline_rounded, title: 'Pusat Bantuan & FAQ', onTap: () {}),
                        _MenuItem(icon: Icons.support_agent_rounded, title: 'Hubungi CS', onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showLogoutConfirmation(context),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Keluar dari Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.redSoft,
                        foregroundColor: AppTheme.red,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFFFD7DC)),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildProfileCard(String? name, String? email) {
    final displayName = (name?.isNotEmpty ?? false) ? name! : 'Pengguna';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.profileGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppTheme.avatarGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                ),
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.ink),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayName,
            style: const TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? 'user@eventkuy.id',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Color(0xFFFFF0A4)),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Member Prioritas EventKuy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFF0A4),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.violet, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup({required String title, required List<_MenuItem> items}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1.2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64, endIndent: 20),
                  InkWell(
                    onTap: items[i].onTap,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(i == 0 ? 20 : 0),
                      bottom: Radius.circular(i == items.length - 1 ? 20 : 0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppTheme.violetSoft, borderRadius: BorderRadius.circular(12)),
                            child: Icon(items[i].icon, color: AppTheme.violet, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              items[i].title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.ink),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textFaint),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.onTap});
}
