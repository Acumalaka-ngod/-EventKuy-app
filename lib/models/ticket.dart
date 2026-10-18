/// Model Ticket — mirror tabel `tickets` Laravel.
/// status: pending | paid | checked_in
class Ticket {
  final String code;
  final int eventId;
  final String eventTitle;
  final String status;

  const Ticket({
    required this.code,
    required this.eventId,
    required this.eventTitle,
    required this.status,
  });

  Ticket copyWith({String? status}) {
    return Ticket(
      code: code,
      eventId: eventId,
      eventTitle: eventTitle,
      status: status ?? this.status,
    );
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      code: json['code'] as String,
      eventId: json['event_id'] as int,
      eventTitle: json['event_title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}
