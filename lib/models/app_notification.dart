/// Model notifikasi in-app — mirror tabel `public.notifications` di Supabase.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? eventId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.eventId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawReadAt = json['read_at']?.toString();
    final rawCreatedAt = json['created_at']?.toString();

    return AppNotification(
      id: json['id'].toString(),
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventId: json['event_id'] as String?,
      isRead: (json['read_at'] as String?) != null,
      readAt: DateTime.tryParse(rawReadAt ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(rawCreatedAt ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'event_id': eventId,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}
