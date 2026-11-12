import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_error_banner.dart';
import '../main_navigation.dart';
import 'auth_layout.dart';
import 'register_screen.dart';

/// Layar Login — form di kanan, brand panel gradient di kiri (desktop).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _serverError;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi.';
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      if (_validateEmail(_emailController.text) != null) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    final error = await context.read<AuthProvider>().login(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _serverError = error;
      });
      return;
    }

    await _loadUserData();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  Future<void> _loadUserData() async {
    // Organizer langsung diarahkan ke dashboard dan tidak memakai data
    // pembeli, jadi jangan muat tiket/favorit untuk akun ini.
    if (context.read<AuthProvider>().user?.isOrganizer == true) return;

    await Future.wait([
      context.read<TicketProvider>().load().catchError((_) {}),
      context.read<FavoriteProvider>().load().catchError((_) {}),
    ]);
  }

  Future<void> _handleForgotPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _serverError = emailError);
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _serverError = null);
    final error = await context.read<AuthProvider>().resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;
    if (error == null) {
      _showMessage(
        'Tautan reset password telah dikirim ke email kamu.',
        AppTheme.accentEmerald,
      );
    } else {
      setState(() => _serverError = error);
    }
  }

  void _socialComingSoon(String provider) {
    _showMessage(
      'Masuk dengan $provider belum tersedia. Gunakan email & password.',
      AppTheme.secondary,
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(form: _buildForm());
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang Kembali',
              style: AppTheme.h1.copyWith(fontSize: 32, letterSpacing: -1.1),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masuk dan temukan pengalaman seru yang sudah menantimu.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            const _FieldLabel(label: 'Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: const InputDecoration(
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Lihat password'
                      : 'Sembunyikan password',
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
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.border, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) =>
                        setState(() => _rememberMe = val ?? false),
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'Ingat saya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_serverError != null) ...[
              FormErrorBanner(message: _serverError!),
              const SizedBox(height: 16),
            ],
            CustomButton(
              label: 'Masuk Sekarang',
              loading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'Atau masuk dengan',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _socialComingSoon('Google'),
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 26,
                      color: Color(0xFFEA4335),
                    ),
                    label: const Text('Google'),
                    style: _socialStyle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _socialComingSoon('Apple'),
                    icon: const Icon(
                      Icons.apple_rounded,
                      size: 22,
                      color: AppTheme.textDark,
                    ),
                    label: const Text('Apple'),
                    style: _socialStyle(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Belum memiliki akun?',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text(
                      'Daftar Sekarang',
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
        ),
      ),
    );
  }

  ButtonStyle _socialStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.textDark,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: const BorderSide(color: AppTheme.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: AppTheme.headingFont,
      ),
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
