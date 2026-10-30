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

    try {
      final profile = await _client
          .from('profiles')
          .select('name, role')
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
