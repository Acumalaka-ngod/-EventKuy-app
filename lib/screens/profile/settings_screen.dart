import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_logo.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';

/// Pusat pengaturan akun: edit profil, keamanan, bantuan, dan info aplikasi.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _open(BuildContext context, Widget screen) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'EventKuy',
      applicationVersion: 'v1.0.0',
      applicationIcon: const EventKuyMark(size: 40),
      children: const [
        Text(
          'Temukan. Ikuti. Hadiri. Aplikasi pembelian tiket event untuk '
          'pengguna dan organizer.',
          style: TextStyle(fontSize: 13, height: 1.6, color: AppTheme.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _sectionTitle('AKUN'),
                _group([
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama dan foto profil',
                    onTap: () => _open(context, const EditProfileScreen()),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    title: 'Ganti Password',
                    subtitle: 'Perbarui kata sandi akun',
                    onTap: () => _open(context, const ChangePasswordScreen()),
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionTitle('BANTUAN'),
                _group([
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Pusat Bantuan & FAQ',
                    subtitle: 'Pertanyaan umum seputar EventKuy',
                    onTap: () => _open(context, const HelpCenterScreen()),
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionTitle('TENTANG'),
                _group([
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    subtitle: 'EventKuy v1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 64, endIndent: 20),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.violet, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
