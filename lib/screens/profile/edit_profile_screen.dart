import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/avatar_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_error_banner.dart';

/// Pemilih gambar yang bisa diganti pada test.
typedef AvatarImagePicker = Future<XFile?> Function(ImageSource source);

/// Edit nama dan foto profil. Avatar diunggah ke Supabase Storage lebih dulu,
/// lalu URL-nya disimpan ke `profiles.avatar_url`.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.avatarService, this.pickImage});

  /// Diisi pada test supaya tidak menyentuh Storage.
  final AvatarService? avatarService;

  /// Diisi pada test supaya tidak memanggil plugin image_picker.
  final AvatarImagePicker? pickImage;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();

  Uint8List? _pickedBytes;
  String? _pickedExtension;
  String? _pickedContentType;
  String? _nameError;
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<AuthProvider>().user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _choosePhoto() async {
    if (!_cameraAvailable) {
      await _pickImage(ImageSource.gallery);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = widget.pickImage != null
          ? await widget.pickImage!(source)
          : await ImagePicker().pickImage(
              source: source,
              maxWidth: 1024,
              imageQuality: 85,
            );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final image = AvatarService.validateImage(
        bytes: bytes,
        extension: _extensionFor(file),
        contentType: file.mimeType,
      );

      setState(() {
        _pickedBytes = bytes;
        _pickedExtension = image.extension;
        _pickedContentType = image.contentType;
      });
    } on AvatarUploadException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Gagal membuka foto. Coba lagi.');
    }
  }

  String _extensionFor(XFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return '';
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final name = _nameController.text.trim();
    final nameError = _validateName(name);

    if (nameError != null) {
      setState(() {
        _nameError = nameError;
        _formError = null;
      });
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _nameError = null;
      _formError = null;
      _saving = true;
    });

    try {
      var avatarUrl = auth.user?.avatarUrl;

      if (_pickedBytes != null) {
        final user = auth.user;
        if (user == null) {
          setState(() => _formError = 'Sesi login tidak ditemukan.');
          return;
        }

        final service = widget.avatarService ?? AvatarService();
        avatarUrl = await service.uploadAvatar(
          userId: user.id,
          bytes: _pickedBytes!,
          extension: _pickedExtension ?? 'jpg',
          contentType: _pickedContentType ?? 'image/jpeg',
        );
      }

      final error = await auth.updateProfile(name: name, avatarUrl: avatarUrl);

      if (!mounted) return;
      if (error != null) {
        setState(() => _formError = error);
        return;
      }

      Navigator.pop(context, true);
    } on AvatarUploadException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Gagal menyimpan profil. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateName(String name) {
    if (name.isEmpty) return 'Nama wajib diisi.';
    if (name.length < 2) return 'Nama minimal 2 karakter.';
    if (name.length > 60) return 'Nama maksimal 60 karakter.';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const SizedBox(height: 8),
                Center(child: _buildAvatar(user)),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _choosePhoto,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Ganti Foto'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'JPG/PNG/WebP, maksimal 5 MB.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ),
                const SizedBox(height: 28),
                const _FieldLabel(
                  label: 'Nama Lengkap',
                  excludeSemantics: true,
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Nama Lengkap',
                  child: TextField(
                    key: const ValueKey('edit-profile-name'),
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.done,
                    maxLength: 60,
                    onChanged: (_) {
                      if (_nameError != null || _formError != null) {
                        setState(() {
                          _nameError = null;
                          _formError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Nama kamu',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                      ),
                      errorText: _nameError,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _FieldLabel(label: 'Email', excludeSemantics: true),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Email',
                  child: TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _FieldLabel(label: 'Peran Akun', excludeSemantics: true),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Peran Akun',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.fieldBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusField),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user?.isOrganizer == true
                              ? Icons.verified_rounded
                              : Icons.person_rounded,
                          size: 20,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user?.isOrganizer == true ? 'Organizer' : 'Pengguna',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email dan peran akun tidak bisa diubah dari aplikasi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  FormErrorBanner(message: _formError!),
                ],
                const SizedBox(height: 28),
                CustomButton(
                  label: 'Simpan Perubahan',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser? user) {
    final displayName = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : 'Pengguna';
    final avatarUrl = user?.avatarUrl;

    Widget content;
    if (_pickedBytes != null) {
      content = Image.memory(
        _pickedBytes!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      );
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      content = Image.network(
        avatarUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialAvatar(displayName),
      );
    } else {
      content = _initialAvatar(displayName);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ClipOval(child: content),
        ),
        Semantics(
          container: true,
          button: true,
          label: 'Ganti foto profil',
          onTap: _saving ? null : _choosePhoto,
          child: ExcludeSemantics(
            child: IconButton(
              onPressed: _saving ? null : _choosePhoto,
              tooltip: 'Ganti foto profil',
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                fixedSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialAvatar(String displayName) {
    return Container(
      width: 110,
      height: 110,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppTheme.avatarGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        displayName.characters.first.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppTheme.headingFont,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.excludeSemantics = false});

  final String label;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.ink,
      ),
    );

    return excludeSemantics ? ExcludeSemantics(child: text) : text;
  }
}
