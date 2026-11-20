import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/services/push_notification_payload.dart';

void main() {
  const eventId = '11111111-1111-4111-8111-000000000001';

  group('PushNotificationPayload.fromData', () {
    test('membaca judul, isi, dan event ID dari data FCM', () {
      final payload = PushNotificationPayload.fromData({
        'title': 'Tiket kamu siap',
        'body': 'Lihat detail pesananmu.',
        'eventId': eventId,
      });

      expect(payload.title, 'Tiket kamu siap');
      expect(payload.body, 'Lihat detail pesananmu.');
      expect(payload.eventId, eventId);
      expect(payload.eventUri, 'eventkuy://event/$eventId');
    });

    test('mendukung kunci event_id (snake_case)', () {
      final payload = PushNotificationPayload.fromData({'event_id': eventId});

      expect(payload.eventId, eventId);
      expect(payload.hasEvent, isTrue);
    });

    test('memakai judul dan isi dari notification bila data kosong', () {
      final payload = PushNotificationPayload.fromData(
        const {},
        fallbackTitle: 'Judul FCM',
        fallbackBody: 'Isi FCM',
      );

      expect(payload.title, 'Judul FCM');
      expect(payload.body, 'Isi FCM');
      expect(payload.hasEvent, isFalse);
      expect(payload.eventUri, isNull);
    });

    test('event ID kosong tidak dianggap deep link', () {
      final payload = PushNotificationPayload.fromData({'eventId': '   '});

      expect(payload.eventId, isNull);
      expect(payload.hasEvent, isFalse);
    });
  });
}
