/// Voucher promo dari tabel `public.vouchers`.
class Voucher {
  final String code;
  final int discount;

  const Voucher({required this.code, required this.discount});

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: json['code'] as String,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
    );
  }
}
