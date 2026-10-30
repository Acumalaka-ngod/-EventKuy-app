import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      _showMessage('Mohon lengkapi semua data wajib.', AppTheme.secondary);
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showMessage('Konfirmasi password belum sama.', AppTheme.secondary);
      return;
    }

    if (!_agreeTerms) {
      _showMessage(
        'Setujui syarat & ketentuan untuk melanjutkan.',
        AppTheme.secondary,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMessage(error, AppTheme.secondary);
      return;
    }

    if (!auth.isLoggedIn) {
      _showMessage(
        'Akun berhasil dibuat. Cek email untuk verifikasi lalu masuk.',
        AppTheme.accentEmerald,
      );
      Navigator.pop(context);
      return;
    }

    await Future.wait([
      context.read<TicketProvider>().load().catchError((_) {}),
      context.read<FavoriteProvider>().load().catchError((_) {}),
    ]);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (_) => false,
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(form: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mulai Petualanganmu',
          style: AppTheme.h1.copyWith(fontSize: 32, letterSpacing: -1.1),
        ),
        const SizedBox(height: 8),
        const Text(
          'Buat akunmu dan jangan lewatkan momen terbaik di kotamu.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppTheme.textMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        const _FieldLabel(label: 'Nama lengkap'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Masukkan nama kamu',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'nama@email.com',
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Minimal 8 karakter',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              tooltip: 'Lihat password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppTheme.textGrey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Konfirmasi password'),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPassword,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRegister(),
          decoration: const InputDecoration(
            hintText: 'Ulangi password',
            prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _agreeTerms,
                  activeColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (val) =>
                      setState(() => _agreeTerms = val ?? false),
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Saya setuju Syarat & Ketentuan serta Kebijakan Privasi EventKuy.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        CustomButton(
          label: 'Daftar Sekarang',
          loading: _isLoading,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: 28),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Sudah punya akun?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Masuk',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }
}
