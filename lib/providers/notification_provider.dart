import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

/// Provider notifikasi in-app (P2 scaffold).
///
/// Mengelola daftar notifikasi milik user dan status baca.
/// Token perangkat untuk push dielola lewat [registerDeviceToken] namun
/// pengiriman push live masih ditunda sampai Firebase tersedia.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;

  final List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get loading => _loading;
  String? get error => _error;

  /// Jumlah notifikasi yang belum dibaca.
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(list);
    } catch (error) {
      _error = 'Gagal memuat notifikasi.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification notification) async {
    try {
      await _api.markNotificationRead(notification.id);
      final i = _notifications.indexWhere((n) => n.id == notification.id);
      if (i != -1) {
        final n = _notifications[i];
        _notifications[i] = AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          body: n.body,
          eventId: n.eventId,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {
      // Abaikan: gagal menandai dibaca, coba lagi pada load berikutnya.
    }
  }

  /// Simpan token push perangkat (no-op saat Firebase belum aktif).
  Future<void> registerDeviceToken({
    required String token,
    String platform = 'unknown',
  }) async {
    await _api.registerDeviceToken(token: token, platform: platform);
  }

  /// Daftar token perangkat terdaftar (untuk debugging/pengelolaan).
  Future<List<String>> fetchDeviceTokens() async =>
      _api.fetchDeviceTokens();
}
