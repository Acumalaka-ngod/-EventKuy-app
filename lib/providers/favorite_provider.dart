import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

/// Favorit user, tersimpan di tabel `public.favorites`.
///
/// Ada dua kumpulan id:
/// - [ids] — status favorit sebenarnya (sumber kebenaran untuk ikon hati).
/// - [shelfIds] — event yang sedang ditampilkan di layar Favorit.
///
/// Melepas favorit hanya mengubah [ids]; kartu tetap ada di [shelfIds]
/// sampai layar dibuka ulang / [syncShelf] dipanggil. Tujuannya supaya
/// salah pencet tombol hati tidak langsung menghilangkan event dari layar.
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;
  final Set<String> _ids = {};
  final Set<String> _shelf = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  /// Event yang ditampilkan di layar Favorit (tidak langsung hilang).
  Set<String> get shelfIds => Set.unmodifiable(_shelf);

  bool isFav(String id) => _ids.contains(id);

  bool onShelf(String id) => _shelf.contains(id);

  Future<void> load() async {
    try {
      final ids = await _api.fetchFavoriteIds();
      _ids
        ..clear()
        ..addAll(ids);
    } catch (_) {
      _ids.clear();
    }
    _shelf
      ..clear()
      ..addAll(_ids);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final wasFavorite = _ids.contains(id);

    if (wasFavorite) {
      _ids.remove(id);
    } else {
      _ids.add(id);
      // Favorit baru langsung muncul di layar Favorit.
      _shelf.add(id);
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
        _shelf.remove(id);
      }
      notifyListeners();
    }
  }

  /// Saring ulang daftar tampilan mengikuti favorit saat ini.
  /// Dipakai saat layar Favorit dibuka kembali.
  void syncShelf() {
    _shelf
      ..clear()
      ..addAll(_ids);
    notifyListeners();
  }

  /// Tombol "Hapus Semua": favorit dan kartu di layar ikut hilang.
  Future<void> clearFavorites() async {
    final removed = _ids.toList(growable: false);
    _ids.clear();
    _shelf.clear();
    notifyListeners();
    for (final id in removed) {
      try {
        await _api.removeFavorite(id);
      } catch (_) {
        // Abaikan: data lokal sudah dikosongkan.
      }
    }
  }

  void clear() {
    _ids.clear();
    _shelf.clear();
    notifyListeners();
  }
}
