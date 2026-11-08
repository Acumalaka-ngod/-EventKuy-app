import 'package:flutter/material.dart';

import '../core/deep_link.dart';

/// Penyedia antrean event ID yang datang dari deep link.
///
/// Deep link dapat tiba sebelum MainNavigation siap (mis. saat splash
/// masih aktif). Event ID disimpan di sini dan dibuka setelah navigasi
/// utama ter-inisialisasi.
class DeepLinkProvider extends ChangeNotifier {
  DeepLinkProvider() : _pendingEventId = null;

  String? _pendingEventId;

  /// ID event yang menunggu dibuka, atau null jika tidak ada.
  String? get pendingEventId => _pendingEventId;

  /// Apakah ada deep link event yang menunggu.
  bool get hasPending => _pendingEventId != null;

  /// Terima deep link URI dari platform. Dieksekusi oleh [DeepLinkHost].
  void handleUri(String? uri) {
    final eventId = DeepLink.eventIdFromUri(uri);
    if (eventId == null) return;
    _pendingEventId = eventId;
    notifyListeners();
  }

  /// Ambil dan hapus ID event yang tertunda. Dipanggil setelah layar
  /// Detail Event berhasil dibuka.
  String? takePending() {
    final id = _pendingEventId;
    _pendingEventId = null;
    notifyListeners();
    return id;
  }

  @override
  String toString() => 'DeepLinkProvider(pending: $_pendingEventId)';
}
