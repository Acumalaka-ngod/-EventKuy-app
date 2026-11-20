import 'deep_link.dart';

/// Jembatan antara callback notifikasi (yang berjalan di luar widget tree)
/// dengan [DeepLinkProvider] yang hidup di dalam widget tree.
///
/// Callback FCM / flutter_local_notifications tidak punya [BuildContext].
/// Router menyimpan URI sementara bila host belum terpasang, lalu memutarnya
/// begitu [setHandler] dipanggil dari `DeepLinkHost.initState`.
class NotificationRouter {
  NotificationRouter._();

  static void Function(String uri)? _handler;
  static String? _pendingUri;

  /// Daftarkan penerima URI. Uri yang tertunda langsung diputar.
  static void setHandler(void Function(String uri) handler) {
    _handler = handler;
    final pending = _pendingUri;
    if (pending != null) {
      _pendingUri = null;
      handler(pending);
    }
  }

  /// Lepaskan penerima saat host di-dispose.
  static void clearHandler() => _handler = null;

  /// Arahkan notifikasi yang diketuk ke halaman Detail Event.
  static void routeToEvent(String? eventId) {
    if (eventId == null || eventId.trim().isEmpty) return;
    final uri = DeepLink.eventUri(eventId.trim());
    final handler = _handler;
    if (handler == null) {
      _pendingUri = uri;
      return;
    }
    handler(uri);
  }

  /// Bersihkan state. Dipakai oleh test dan saat hot restart.
  static void reset() {
    _handler = null;
    _pendingUri = null;
  }
}
