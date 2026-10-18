import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation.dart';
import 'register_screen.dart';

/// Layar Login — Responsif:
/// - Mobile/Tablet : form di tengah (max 480)
/// - Desktop       : split view — panel branding kiri + form kanan
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'user');
  final _emailController = TextEditingController(text: 'user@ajangin.id');
  final _passwordController = TextEditingController(text: 'secret123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi nama dan email Anda'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await context.read<AuthProvider>().loginDummy(name, email);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildCenteredForm(showBrandHeader: true),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildBrandPanel()),
              Expanded(
                flex: 6,
                child: _buildCenteredForm(showBrandHeader: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredForm({required bool showBrandHeader}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildFormColumn(showBrandHeader: showBrandHeader),
        ),
      ),
    );
  }

  Widget _buildFormColumn({required bool showBrandHeader}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrandHeader) ...[
          const SizedBox(height: 20),
          _buildBrandHeaderRow(),
          const SizedBox(height: 32),
        ],
        // Greeting
        const Text(
          'Selamat Datang Kembali',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Masuk ke akunmu untuk mengeksplor event dan tiket menarik di sekitarmu.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Form Container
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Akun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimal 8 karakter',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textGrey,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (val) =>
                          setState(() => _rememberMe = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ingat saya',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Masuk Sekarang',
                loading: _isLoading,
                icon: Icons.login_rounded,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        // Divider Sosial
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Atau masuk dengan',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.border)),
          ],
        ),
        const SizedBox(height: 20),

        // Social Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleLogin(),
                icon: const Icon(Icons.g_mobiledata_rounded,
                    size: 26, color: Color(0xFFEA4335)),
                label: const Text('Google',
                    style: TextStyle(color: AppTheme.textDark)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleLogin(),
                icon: const Icon(Icons.apple_rounded,
                    size: 24, color: AppTheme.textDark),
                label: const Text('Apple',
                    style: TextStyle(color: AppTheme.textDark)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        // Footer Register Link
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Belum memiliki akun? ',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  'Daftar Sekarang',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBrandHeaderRow() {
    return const AjanginLogo(markSize: 38, fontSize: 19);
  }

  /// Panel branding untuk tampilan desktop (split view)
  Widget _buildBrandPanel() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        gradient: AppTheme.ticketGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AjanginMark(size: 54, onDark: true),
          const SizedBox(height: 28),
          const Text(
            'AJANGIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Satu aplikasi untuk menemukan konser, seminar, workshop, hingga lari maraton favoritmu.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildFeatureRow(
              Icons.confirmation_number_rounded, 'Beli tiket dalam hitungan detik'),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.qr_code_2_rounded,
              'E-tiket QR untuk check-in cepat di venue'),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.local_activity_rounded,
              'Promo, voucher, dan poin reward eksklusif'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
