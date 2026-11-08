import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../core/errors.dart';
import '../models/user.dart';

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
    var name = (user.userMetadata?['name'] as String?)?.trim() ?? '';
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

      await _client.from('profiles').update({
        'name': trimmed,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
      }).eq('id', current.id);

      await _client.auth.updateUser(
        UserAttributes(data: {'name': trimmed}),
      );
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
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Tetap bersihkan state lokal walau jaringan bermasalah.
    }
    _user = null;
    notifyListeners();
  }
}
