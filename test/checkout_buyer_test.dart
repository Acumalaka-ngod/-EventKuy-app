import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/checkout_result.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/transaction_record.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

Event _event() => Event(
  id: '11111111-1111-4111-8111-000000000001',
  title: 'Konser Buyer',
  description: 'Konser untuk uji data pembeli.',
  date: DateTime(2026, 11, 8, 19),
  location: 'Jakarta',
  price: 150000,
  quota: 100,
  imageUrl: '',
  category: 'Konser',
);

Widget _app(Event event, {AuthProvider? auth, TicketProvider? tickets}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider(
        create: (_) =>
            tickets ??
            TicketProvider(api: MockApiService(), pollInterval: null),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: CheckoutScreen(event: event),
    ),
  );
}

Future<void> _fillValidBuyer(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Siti Rahma');
  await tester.enterText(find.byType(TextFormField).at(1), 'siti@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), '081234567890');
  await tester.pump();
}

class _CapturingTicketProvider extends TicketProvider {
  _CapturingTicketProvider() : super(api: MockApiService(), pollInterval: null);

  String? capturedBuyerName;
  String? capturedBuyerEmail;
  String? capturedBuyerPhone;

  @override
  Future<CheckoutResult> checkout(
    Event event, {
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  }) async {
    capturedBuyerName = buyerName;
    capturedBuyerEmail = buyerEmail;
    capturedBuyerPhone = buyerPhone;
    return super.checkout(
      event,
      qty: qty,
      voucherCode: voucherCode,
      paymentMethod: paymentMethod,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
    );
  }
}

void main() {
  group('Persistensi data pembeli', () {
    testWidgets('UI mengirim nilai form ke provider checkout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event();
      final provider = _CapturingTicketProvider();
      await tester.pumpWidget(_app(event, tickets: provider));
      await tester.pump();

      await _fillValidBuyer(tester);
      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(provider.capturedBuyerName, 'Siti Rahma');
      expect(provider.capturedBuyerEmail, 'siti@example.com');
      expect(provider.capturedBuyerPhone, '081234567890');
      expect(tester.takeException(), isNull);
    });

    testWidgets('field kosong tetap ditolak UI', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event();
      await tester.pumpWidget(_app(event));
      await tester.pump();

      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Nomor HP wajib diisi.'), findsOneWidget);
    });
  });

  group('MockApiService menyimpan buyer', () {
    test('checkout menyimpan nama/email/HP pada transaksi', () async {
      final api = MockApiService();
      await api.checkout(
        eventId: '11111111-1111-4111-8111-000000000001',
        buyerName: 'Siti Rahma',
        buyerEmail: 'siti@example.com',
        buyerPhone: '081234567890',
      );

      final trx = await api.fetchTransactions();
      expect(trx, isNotEmpty);
      final first = trx.first;
      expect(first.buyerName, 'Siti Rahma');
      expect(first.buyerEmail, 'siti@example.com');
      expect(first.buyerPhone, '081234567890');
    });

    test('TransactionRecord.fromJson membaca buyer fields', () {
      final trx = TransactionRecord.fromJson({
        'id': 'trx-1',
        'events': {'title': 'Konser Buyer'},
        'tickets': {'code': 'EVK-001'},
        'total': 152500,
        'payment_method': 'GoPay',
        'status': 'paid',
        'created_at': '2026-11-08T19:00:00Z',
        'buyer_name': 'Siti Rahma',
        'buyer_email': 'siti@example.com',
        'buyer_phone': '081234567890',
      });
      expect(trx.buyerName, 'Siti Rahma');
      expect(trx.buyerEmail, 'siti@example.com');
      expect(trx.buyerPhone, '081234567890');
    });
  });
}
