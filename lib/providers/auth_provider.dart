import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Auth dummy — nanti hit POST /api/login & /register Laravel (Fase 1).
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      _user = AppUser(
        id: 1,
        name: prefs.getString('user_name') ?? 'Pengguna',
        email: email,
      );
      notifyListeners();
    }
  }

  Future<void> loginDummy(String name, String email) async {
    _user = AppUser(id: 1, name: name, email: email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
