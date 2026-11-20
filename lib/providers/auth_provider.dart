import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../models/user.dart';
import '../services/google_auth_service.dart';
import '../services/push_messaging_service.dart';

/// Auth Supabase (email + password) dengan profil dari tabel `profiles`.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  SupabaseClient get _client {
    if (!AppConfig.hasSupabaseConfig) {
      throw StateError('Supabase belum dikonfigurasi.');
    }
    return Supabase.instance.client;
  }

  Future<AppUser> _toAppUser(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    var name = (metadata['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      name = (metadata['full_name'] as String?)?.trim() ?? '';
    }
    var role = 'pengguna';
    String? avatarUrl;

    try {
      final profile = await _client
          .from('profiles')
          .select('name, role, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      final profileName = profile?['name'] as String?;
      if (profileName != null && profileName.trim().isNotEmpty) {
        name = profileName.trim();
      }
      final profileRole = profile?['role'] as String?;
      if (profileRole != null && profileRole.trim().isNotEmpty) {
        role = profileRole.trim();
      }
      final profileAvatar = profile?['avatar_url'] as String?;
      if (profileAvatar != null && profileAvatar.trim().isNotEmpty) {
        avatarUrl = profileAvatar.trim();
      }
    } catch (_) {
      // Profil belum terbaca — pakai metadata auth sebagai fallback.
    }

    if (avatarUrl == null) {
      final metadataAvatar = metadata['avatar_url'] ?? metadata['picture'];
      if (metadataAvatar is String && metadataAvatar.trim().isNotEmpty) {
        avatarUrl = metadataAvatar.trim();
      }
    }

    if (name.isEmpty) {
      name = user.email?.split('@').first ?? 'Pengguna';
    }

    return AppUser(
      id: user.id,
      name: name,
      email: user.email ?? '',
      role: role,
      avatarUrl: avatarUrl,
    );
  }

  Future<bool> tryAutoLogin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      _user = await _toAppUser(user);
      notifyListeners();
      return true;
    } catch (_) {
      _user = null;
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        _user = await _toAppUser(user);
        notifyListeners();
      }
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  /// Masuk dengan Google lalu tukar ID token menjadi sesi Supabase.
  Future<String?> signInWithGoogle() async {
    try {
      final result = await GoogleAuthService.instance.signIn();
      if (result.canceled) return null;
      if (result.error != null) return result.error;

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: result.idToken!,
      );
      final user = response.user;
      if (user != null) {
        _user = await _toAppUser(user);
        notifyListeners();
      }
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final user = response.user;
      if (response.session != null && user != null) {
        _user = await _toAppUser(user);
        notifyListeners();
      }
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  /// Simpan nama dan/atau avatar baru. `avatarUrl` null berarti tidak diubah.
  Future<String?> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    final trimmed = name.trim();
    if (trimmed.length < 2) return 'Nama minimal 2 karakter.';
    if (trimmed.length > 60) return 'Nama maksimal 60 karakter.';

    try {
      final current = _client.auth.currentUser;
      if (current == null) return 'Sesi login tidak ditemukan.';

      await _client
          .from('profiles')
          .update({
            'name': trimmed,
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              'avatar_url': avatarUrl,
          })
          .eq('id', current.id);

      await _client.auth.updateUser(UserAttributes(data: {'name': trimmed}));
      await _refreshUser();
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  /// Ganti password setelah memverifikasi password saat ini.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      return 'Password baru minimal 8 karakter.';
    }
    if (newPassword == currentPassword) {
      return 'Password baru harus berbeda dari password lama.';
    }

    final storedEmail = _user?.email;
    final email = (storedEmail != null && storedEmail.isNotEmpty)
        ? storedEmail
        : _client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      return 'Sesi login tidak ditemukan.';
    }

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (_) {
      return 'Password saat ini salah.';
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  Future<void> _refreshUser() async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    _user = await _toAppUser(current);
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      return 'Masukkan email terlebih dahulu.';
    }
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  Future<void> logout() async {
    // Hapus token push sebelum sesi Supabase berakhir agar notifikasi
    // pengguna ini tidak ikut terkirim ke pengguna berikutnya di perangkat.
    await PushMessagingService.instance.clearToken();
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Tetap bersihkan state lokal walau jaringan bermasalah.
    }
    await GoogleAuthService.instance.signOut();
    _user = null;
    notifyListeners();
  }

  /// Hapus akun beserta data terkait di Supabase, lalu bersihkan sesi lokal.
  ///
  /// RPC `delete_account` (supabase/account_deletion.sql) berjalan sebagai
  /// security definer dan menghapus baris auth.users, sehingga token lama
  /// otomatis tidak valid lagi.
  Future<void> deleteAccount() async {
    await PushMessagingService.instance.clearToken();
    await _client.rpc('delete_account');
    try {
      // Baris auth sudah hilang, jadi signOut bisa gagal secara jaringan.
      // State lokal tetap dibersihkan di bawah.
      await _client.auth.signOut();
    } catch (_) {}
    await GoogleAuthService.instance.signOut();
    _user = null;
    notifyListeners();
  }
}
