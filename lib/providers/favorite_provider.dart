import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favorit user — persist lokal. Nanti bisa sync ke Laravel (Fase 3).
class FavoriteProvider extends ChangeNotifier {
  static const _key = 'favorite_event_ids';
  final Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);
  bool isFav(int id) => _ids.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_key)?.map(int.parse) ?? []);
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _ids.map((e) => e.toString()).toList());
    notifyListeners();
  }
}
