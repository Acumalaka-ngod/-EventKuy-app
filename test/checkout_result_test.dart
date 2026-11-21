import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/models/checkout_result.dart';

void main() {
  group('CheckoutResult.fromRpc', () {
    test('mode live: pesanan pending dan tiket belum aktif', () {
      final result = CheckoutResult.fromRpc({
        'event_id': 'e1',
        'event_title': 'Konser Malam',
        'ticket_codes': ['EVK-1', 'EVK-2'],
        'subtotal': 200000,
        'admin_fee': 5000,
        'discount': 25000,
        'total': 180000,
        'status': 'pending',
        'payment_mode': 'live',
        'checkout_group_id': 'group-1',
        'expires_at': '2026-11-21T10:00:00+07:00',
      });

      expect(result.isPending, isTrue);
      expect(result.isSimulation, isFalse);
      expect(result.status, 'pending');
      expect(result.paymentMode, 'live');
      expect(result.checkoutGroupId, 'group-1');
      expect(result.expiresAt, isNotNull);
      expect(result.qty, 2);
      expect(result.tickets.every((t) => t.status == 'pending'), isTrue);
    });

    test('mode simulasi: tiket langsung paid dan ditandai simulasi', () {
      final result = CheckoutResult.fromRpc({
        'event_id': 'e1',
        'event_title': 'Konser Malam',
        'ticket_codes': ['EVK-1'],
        'subtotal': 100000,
        'admin_fee': 2500,
        'discount': 0,
        'total': 102500,
        'status': 'paid',
        'payment_mode': 'simulation',
        'checkout_group_id': 'group-2',
      });

      expect(result.isPending, isFalse);
      expect(result.isSimulation, isTrue);
      expect(result.expiresAt, isNull);
      expect(result.ticket.status, 'paid');
    });

    test('respons lama tanpa field baru tetap dianggap paid + simulasi', () {
      final result = CheckoutResult.fromRpc({
        'event_id': 'e1',
        'event_title': 'Konser Lama',
        'ticket_code': 'EVK-LAMA',
        'subtotal': 50000,
        'admin_fee': 2500,
        'discount': 0,
        'total': 52500,
      });

      expect(result.isPending, isFalse);
      expect(result.isSimulation, isTrue);
      expect(result.checkoutGroupId, isNull);
      expect(result.codes, ['EVK-LAMA']);
    });
  });
}
