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

/// Layar Profil Pengguna — Kartu Profil, Stat Counter, Pengaturan Akun, & Logout Dialog
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.secondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Keluar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apakah Anda yakin ingin keluar dari akun AjangIn?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(color: AppTheme.textDark)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Ya, Keluar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan aplikasi akan hadir segera!')),
              );
            },
          ),
        ],
      ),
      body: ConstrainedContent(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Profil Card Mewah
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          (user?.name.isNotEmpty ?? false)
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Nama Pengguna',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? 'user@ajangin.id',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 15, color: AppTheme.accentAmber),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Member Prioritas AjangIn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stat Counter Row (Tiket, Favorit, Poin)
          Row(
            children: [
              _buildStatCard('Tiket Saya', '$ticketCount', Icons.confirmation_number_outlined, AppTheme.primary),
              const SizedBox(width: 12),
              _buildStatCard('Favorit', '$favCount', Icons.favorite_border_rounded, AppTheme.secondary),
              const SizedBox(width: 12),
              _buildStatCard('Poin Reward', '1.250', Icons.stars_rounded, AppTheme.accentAmber),
            ],
          ),
          const SizedBox(height: 24),

          // Menu Akun & Aktivitas
          const Text(
            'AKUN & AKTIVITAS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Informasi Profil',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat Pesanan & Transaksi',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Metode Pembayaran Tersimpan',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Mode Organizer
          const Text(
            'MODE ORGANIZER',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Dashboard Organizer',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrganizerDashboardScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildMenuItem(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan QR Check-in (Panitia)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Bantuan & Info
          const Text(
            'BANTUAN & PUSAT INFORMASI',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Pusat Bantuan & FAQ',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Hubungi Customer Care',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildMenuItem(
                  icon: Icons.policy_outlined,
                  title: 'Ketentuan Layanan & Privasi',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Keluar (Logout)
          Material(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => _showLogoutConfirmation(context),
              leading: const Icon(Icons.logout_rounded, color: AppTheme.secondary),
              title: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.secondary),
            ),
          ),
          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppTheme.textGrey,
      ),
      onTap: onTap,
    );
  }
}
