import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/services/mock_api_service.dart';

/// Aturan checkout: qty tiket + stok + voucher sekali pakai per user.
void main() {
  group('Checkout — jumlah tiket (qty)', () {
    test('membeli 3 tiket menghasilkan 3 kode unik dan total per tiket', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final event = (await api.fetchEvents()).first;
      final result = await provider.checkout(event, qty: 3);

      expect(result.tickets.length, 3);
      expect(result.tickets.map((t) => t.code).toSet().length, 3);
      expect(result.subtotal, event.price * 3);
      expect(result.adminFee, 2500 * 3);
      expect(result.total, event.price * 3 + 2500 * 3);
      expect(provider.tickets.length, 3);
    });

    test('qty default tetap satu tiket', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final event = (await api.fetchEvents()).first;
      final result = await provider.checkout(event);

      expect(result.tickets.length, 1);
      expect(result.total, event.price + 2500);
    });
  });

  group('Checkout — stok tiket', () {
    test('qty melebihi sisa stok ditolak dan tidak membuat tiket', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      // Event dengan kuota kecil supaya skenario cepat.
      final event = (await api.fetchEvents()).firstWhere((e) => e.quota <= 300);
      await provider.checkout(event, qty: event.quota - 2);

      await expectLater(
        provider.checkout(event, qty: 3),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'pesan',
            contains('Sisa'),
          ),
        ),
      );
      expect(provider.tickets.length, event.quota - 2);
    });

    test('setelah stok terakhir terjual, event ditandai habis', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final event = (await api.fetchEvents()).firstWhere((e) => e.quota <= 300);
      await provider.checkout(event, qty: event.quota);

      await expectLater(
        provider.checkout(event, qty: 1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'pesan',
            contains('habis'),
          ),
        ),
      );

      final refreshed = (await api.fetchEvents())
          .firstWhere((e) => e.id == event.id);
      expect(refreshed.isSoldOut, isTrue);
      expect(refreshed.available, 0);
    });
  });

  group('Voucher — sekali pakai per user', () {
    test('voucher yang sama ditolak pada transaksi kedua', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final event = (await api.fetchEvents()).first;
      final first = await provider.checkout(event, voucherCode: 'EVENTKUY');
      expect(first.discount, 25000);
      expect(first.total, event.price + 2500 - 25000);

      await expectLater(
        provider.checkout(event, voucherCode: 'eventkuy'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'pesan',
            contains('sudah pernah'),
          ),
        ),
      );
      expect(provider.tickets.length, 1);
    });

    test('voucher lain masih bisa dipakai setelah satu voucher terpakai', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final event = (await api.fetchEvents()).first;
      await provider.checkout(event, voucherCode: 'EVENTKUY');
      final second = await provider.checkout(event, voucherCode: 'DISKON10');

      expect(second.discount, 25000);
    });

    test('fetchUsedVoucherCodes menandai voucher yang sudah dipakai user', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      expect(await provider.fetchUsedVoucherCodes(), isEmpty);

      await provider.checkout(
        (await api.fetchEvents()).first,
        voucherCode: 'EVENTKUY',
      );

      final used = await provider.fetchUsedVoucherCodes();
      expect(used, contains('EVENTKUY'));
      expect(used, isNot(contains('DISKON10')));
    });

    test('voucher tidak valid ditolak sebelum tiket dibuat', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      await expectLater(
        provider.checkout(
          (await api.fetchEvents()).first,
          voucherCode: 'TIDAKADA',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'pesan',
            contains('tidak valid'),
          ),
        ),
      );
      expect(provider.tickets, isEmpty);
    });
  });
}
