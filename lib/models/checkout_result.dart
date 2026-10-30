import 'ticket.dart';

/// Hasil satu transaksi checkout: bisa berisi beberapa tiket (qty > 1).
class CheckoutResult {
  final List<Ticket> tickets;
  final int subtotal;
  final int adminFee;
  final int discount;
  final int total;

  const CheckoutResult({
    required this.tickets,
    required this.subtotal,
    required this.adminFee,
    required this.discount,
    required this.total,
  });

  /// Jumlah tiket yang dibeli.
  int get qty => tickets.length;

  /// Tiket pertama (dipakai untuk ringkasan / dialog sukses).
  Ticket get ticket => tickets.first;

  /// Daftar kode tiket, mis. `["EVK-AB12", "EVK-CD34"]`.
  List<String> get codes => tickets.map((t) => t.code).toList(growable: false);

  /// Bangun hasil dari balasan RPC `checkout`.
  factory CheckoutResult.fromRpc(Map<String, dynamic> json) {
    final eventId = json['event_id'].toString();
    final eventTitle = json['event_title'] as String? ?? '';
    final status = json['status'] as String? ?? 'paid';

    final rawCodes = json['ticket_codes'];
    final codes = rawCodes is List
        ? rawCodes.map((code) => code.toString()).toList(growable: false)
        : <String>[
            if (json['ticket_code'] != null) json['ticket_code'].toString(),
          ];

    return CheckoutResult(
      tickets: codes
          .map(
            (code) => Ticket(
              code: code,
              eventId: eventId,
              eventTitle: eventTitle,
              status: status,
            ),
          )
          .toList(growable: false),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      adminFee: (json['admin_fee'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
