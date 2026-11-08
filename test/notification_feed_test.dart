import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/models/app_notification.dart';
import 'package:eventkuy/services/mock_api_service.dart';

void main() {
  group('NotificationProvider with MockApiService', () {
    test('fetchNotifications mengembalikan daftar notifikasi mock', () async {
      final api = MockApiService();
      api.seedNotification(
        id: 'n1',
        userId: 'u1',
        title: 'Tiket Anda telah dikonfirmasi',
        body: 'E-tiket untuk Konser Senja sudah tersedia.',
      );
      api.seedNotification(
        id: 'n2',
        userId: 'u1',
        title: 'Pengingat acara',
        body: 'Besok ada UI/UX Design Workshop di GoWork.',
        eventId: 'evt-workshop',
        isRead: true,
      );

      final notifications = await api.fetchNotifications();
      expect(notifications, hasLength(2));
      expect(notifications[0].title, 'Tiket Anda telah dikonfirmasi');
      expect(notifications[1].title, 'Pengingat acara');
      expect(notifications[1].isRead, isTrue);
    });

    test('markNotificationRead menandai notifikasi sebagai dibaca', () async {
      final api = MockApiService();
      api.seedNotification(
        id: 'n1',
        userId: 'u1',
        title: 'Notifikasi baru',
        body: 'Ini adalah notifikasi uji coba.',
      );

      final notifications = await api.fetchNotifications();
      expect(notifications.first.isRead, isFalse);

      await api.markNotificationRead('n1');

      final updated = await api.fetchNotifications();
      expect(updated.first.isRead, isTrue);
      expect(updated.first.readAt, isNotNull);
    });

    test('registerDeviceToken menyimpan token', () async {
      final api = MockApiService();
      await api.registerDeviceToken(
        token: 'fcm-token-abc-123',
        platform: 'android',
      );

      final tokens = await api.fetchDeviceTokens();
      expect(tokens, contains('fcm-token-abc-123'));
    });

    test('AppNotification.fromJson parsing', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'user_id': 'u1',
        'title': 'Judul Notifikasi',
        'body': 'Isi notifikasi.',
        'event_id': 'evt-1',
        'read_at': '2026-11-08T19:00:00Z',
        'created_at': '2026-11-08T18:00:00Z',
      });
      expect(n.id, 'n1');
      expect(n.title, 'Judul Notifikasi');
      expect(n.body, 'Isi notifikasi.');
      expect(n.eventId, 'evt-1');
      expect(n.isRead, isTrue);
      expect(n.readAt, isNotNull);
    });

    test('AppNotification.isRead false bila read_at null', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'user_id': 'u1',
        'title': 'Judul',
        'body': 'Isi.',
        'read_at': null,
      });
      expect(n.isRead, isFalse);
      expect(n.readAt, isNull);
    });
  });
}
