/// Model transaksi — mirror tabel `public.transactions` di Supabase.
/// status: pending | paid | failed | refunded
class TransactionRecord {
  final String id;
  final String eventTitle;
  final String ticketCode;
  final double total;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  /// Data pembeli yang disimpan pada transaksi (P2).
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;

  const TransactionRecord({
    required this.id,
    required this.eventTitle,
    required this.ticketCode,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.buyerName = '',
    this.buyerEmail = '',
    this.buyerPhone = '',
  });

  /// `events(title)` dan `tickets(code)` datang sebagai objek bersarang dari
  /// PostgREST. Kalau join gagal/kosong, nilainya dibiarkan kosong.
  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final event = json['events'];
    final ticket = json['tickets'];
    final rawDate = json['created_at']?.toString();

    return TransactionRecord(
      id: json['id'].toString(),
      eventTitle: event is Map ? (event['title'] as String? ?? '') : '',
      ticketCode: ticket is Map ? (ticket['code'] as String? ?? '') : '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? '-',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(rawDate ?? '')?.toLocal() ?? DateTime.now(),
      buyerName: json['buyer_name'] as String? ?? '',
      buyerEmail: json['buyer_email'] as String? ?? '',
      buyerPhone: json['buyer_phone'] as String? ?? '',
    );
  }
}
