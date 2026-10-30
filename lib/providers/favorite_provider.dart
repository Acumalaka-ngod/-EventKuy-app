import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

/// Favorit user, tersimpan di tabel `public.favorites`.
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);
  bool isFav(String id) => _ids.contains(id);

  Future<void> load() async {
    try {
      final ids = await _api.fetchFavoriteIds();
      _ids
        ..clear()
        ..addAll(ids);
    } catch (_) {
      _ids.clear();
    }
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final wasFavorite = _ids.contains(id);

    if (wasFavorite) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _api.removeFavorite(id);
      } else {
        await _api.addFavorite(id);
      }
    } catch (_) {
      if (wasFavorite) {
        _ids.add(id);
      } else {
        _ids.remove(id);
      }
      notifyListeners();
    }
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }
}
