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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _serverError;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama lengkap wajib diisi.';
    if (name.length < 2) return 'Nama minimal 2 karakter.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password wajib diisi.';
    if (password.length < 8) return 'Password minimal 8 karakter.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }
    if (value != _password.text) return 'Konfirmasi password belum sama.';
    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      if (_validateName(_name.text) != null) {
        _nameFocus.requestFocus();
      } else if (_validateEmail(_email.text) != null) {
        _emailFocus.requestFocus();
      } else if (_validatePassword(_password.text) != null) {
        _passwordFocus.requestFocus();
      } else if (_validateConfirmPassword(_confirmPassword.text) != null) {
        _confirmFocus.requestFocus();
      }
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

    if (error != null) {
      setState(() {
        _isLoading = false;
        _serverError = error;
      });
      return;
    }

    setState(() => _isLoading = false);

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
            TextFormField(
              controller: _name,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: _validateName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              decoration: const InputDecoration(
                hintText: 'Masukkan nama kamu',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
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
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
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
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Konfirmasi password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPassword,
              focusNode: _confirmFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateConfirmPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: const InputDecoration(
                hintText: 'Ulangi password',
                prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            FormField<bool>(
              initialValue: _agreeTerms,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => (value ?? false)
                  ? null
                  : 'Setujui syarat & ketentuan untuk melanjutkan.',
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Checkbox(
                            value: field.value ?? false,
                            activeColor: AppTheme.primary,
                            side: const BorderSide(
                              color: AppTheme.border,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (val) {
                              final checked = val ?? false;
                              setState(() => _agreeTerms = checked);
                              field.didChange(checked);
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: Text(
                              'Saya setuju Syarat & Ketentuan serta Kebijakan Privasi EventKuy.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 50, top: 4),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.red,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_serverError != null) ...[
              FormErrorBanner(message: _serverError!),
              const SizedBox(height: 16),
            ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 48),
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
        ),
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
