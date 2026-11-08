import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_error_banner.dart';

/// Ganti password dengan verifikasi password lama.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _formError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    String? currentError;
    String? newError;
    String? confirmError;

    if (current.isEmpty) {
      currentError = 'Masukkan password saat ini.';
    } else if (next.length < 8) {
      newError = 'Password baru minimal 8 karakter.';
    } else if (next != confirm) {
      confirmError = 'Konfirmasi password tidak cocok.';
    } else if (next == current) {
      newError = 'Password baru harus berbeda dari password lama.';
    }

    if (currentError != null || newError != null || confirmError != null) {
      setState(() {
        _currentError = currentError;
        _newError = newError;
        _confirmError = confirmError;
        _formError = null;
      });
      if (currentError != null) {
        _currentFocus.requestFocus();
      } else if (newError != null) {
        _newFocus.requestFocus();
      } else {
        _confirmFocus.requestFocus();
      }
      return;
    }

    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
      _formError = null;
      _saving = true;
    });

    final error = await context.read<AuthProvider>().changePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    _showMessage('Password berhasil diubah.', AppTheme.green);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Ganti Password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.violetSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.violet,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Amankan akunmu',
                  style: AppTheme.h2.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan password saat ini untuk memastikan perubahan '
                  'dilakukan oleh pemilik akun.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 28),
                _passwordField(
                  fieldKey: const ValueKey('current-password'),
                  controller: _currentController,
                  focusNode: _currentFocus,
                  label: 'Password Saat Ini',
                  hint: 'Masukkan password lama',
                  obscure: _obscureCurrent,
                  errorText: _currentError,
                  onChanged: (_) {
                    if (_currentError != null || _formError != null) {
                      setState(() {
                        _currentError = null;
                        _formError = null;
                      });
                    }
                  },
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  fieldKey: const ValueKey('new-password'),
                  controller: _newController,
                  focusNode: _newFocus,
                  label: 'Password Baru',
                  hint: 'Minimal 8 karakter',
                  obscure: _obscureNew,
                  errorText: _newError,
                  onChanged: (_) {
                    if (_newError != null || _formError != null) {
                      setState(() {
                        _newError = null;
                        _formError = null;
                      });
                    }
                  },
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  fieldKey: const ValueKey('confirm-password'),
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  label: 'Konfirmasi Password Baru',
                  hint: 'Ulangi password baru',
                  obscure: _obscureConfirm,
                  errorText: _confirmError,
                  onChanged: (_) {
                    if (_confirmError != null || _formError != null) {
                      setState(() {
                        _confirmError = null;
                        _formError = null;
                      });
                    }
                  },
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  FormErrorBanner(message: _formError!),
                ],
                const SizedBox(height: 28),
                CustomButton(
                  key: const ValueKey('change-password-submit'),
                  label: 'Simpan Password Baru',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Setelah password berubah, gunakan password baru saat login '
                  'berikutnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required Key fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool obscure,
    required String? errorText,
    required ValueChanged<String> onChanged,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              errorText: errorText,
              suffixIcon: Semantics(
                container: true,
                button: true,
                label: obscure ? 'Lihat password' : 'Sembunyikan password',
                onTap: onToggle,
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: obscure
                        ? 'Lihat password'
                        : 'Sembunyikan password',
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textFaint,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
                    onPressed: onToggle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
