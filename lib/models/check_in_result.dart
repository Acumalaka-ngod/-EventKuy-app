/// Hasil RPC `check_in_ticket` — berisi kode tiket dan judul event.
class CheckInResult {
  final String code;
  final String eventTitle;

  const CheckInResult({required this.code, required this.eventTitle});

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      code: json['code'] as String? ?? '',
      eventTitle: json['event_title'] as String? ?? '',
    );
  }
}
