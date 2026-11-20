import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/deep_link.dart';

/// Data push notifikasi EventKuy yang sudah dinormalisasi.
///
/// Edge Function `send-push` mengirim `title`, `body`, dan `eventId` lewat
/// field `data` FCM. Field `notification` tetap diisi agar sistem Android
/// menampilkan notifikasi saat aplikasi di background/terminated.
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.title,
    required this.body,
    this.eventId,
  });

  final String title;
  final String body;
  final String? eventId;

  /// Apakah notifikasi membuka halaman Detail Event.
  bool get hasEvent => eventUri != null;

  /// Deep link `eventkuy://event/<id>` untuk event terkait, bila ada.
  String? get eventUri {
    final id = eventId;
    if (id == null || id.isEmpty) return null;
    return DeepLink.eventUri(id);
  }

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return PushNotificationPayload.fromData(
      message.data,
      fallbackTitle: message.notification?.title,
      fallbackBody: message.notification?.body,
    );
  }

  factory PushNotificationPayload.fromData(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    return PushNotificationPayload(
      title: _text(data['title']) ?? fallbackTitle ?? 'Notifikasi EventKuy',
      body: _text(data['body']) ?? fallbackBody ?? '',
      eventId: _text(data['eventId']) ?? _text(data['event_id']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
