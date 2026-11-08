import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

/// Favorit user, tersimpan di tabel `public.favorites`.
///
/// Melepas favorit langsung menghilangkan kartu dari layar Favorit. Aksi
/// "Hapus Semua" bisa diurungkan lewat [restoreFavorites].
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;
  final Set<String> _ids = {};
  bool _loading = false;
  String? _error;

  Set<String> get ids => Set.unmodifiable(_ids);
  bool get loading => _loading;
  String? get error => _error;

  bool isFav(String id) => _ids.contains(id);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final ids = await _api.fetchFavoriteIds();
      _ids
        ..clear()
        ..addAll(ids);
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
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

  /// Tombol "Hapus Semua": favorit langsung hilang dari layar.
  Future<void> clearFavorites() async {
    final removed = _ids.toList(growable: false);
    _ids.clear();
    notifyListeners();

    for (final id in removed) {
      try {
        await _api.removeFavorite(id);
      } catch (_) {
        // Abaikan: data lokal sudah dikosongkan dan undo tetap tersedia.
      }
    }
  }

  /// Kembalikan favorit yang baru dihapus lewat aksi "Urungkan".
  Future<void> restoreFavorites(Iterable<String> ids) async {
    _ids.addAll(ids);
    notifyListeners();

    for (final id in ids) {
      try {
        await _api.addFavorite(id);
      } catch (_) {
        // Abaikan: status lokal sudah dikembalikan.
      }
    }
  }

  void clear() {
    _ids.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
