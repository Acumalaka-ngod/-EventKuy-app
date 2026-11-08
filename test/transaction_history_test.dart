import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/transaction_record.dart';
import 'package:eventkuy/screens/profile/transaction_history_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart' show formatRp;

class _FailingApi extends MockApiService {
  @override
  Future<List<TransactionRecord>> fetchTransactions() async {
    throw StateError('jaringan mati');
  }
}

Widget _app({required MockApiService api}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: TransactionHistoryScreen(api: api),
  );
}

Future<Event> _seed(
  WidgetTester tester,
  MockApiService api, {
  int qty = 1,
  String? voucherCode,
}) async {
  late Event event;
  await tester.runAsync(() async {
    event = (await api.fetchEvents()).first;
    await api.checkout(
      eventId: event.id,
      qty: qty,
      voucherCode: voucherCode,
      paymentMethod: 'GoPay',
    );
  });
  return event;
}

void main() {
  testWidgets('empty state tampil saat belum ada transaksi', (tester) async {
    await tester.pumpWidget(_app(api: MockApiService()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-empty')), findsOneWidget);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daftar transaksi menampilkan data lengkap dan format Rupiah', (
    tester,
  ) async {
    final api = MockApiService();
    final event = await _seed(tester, api);

    await tester.pumpWidget(_app(api: api));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-list')), findsOneWidget);
    expect(find.text(event.title), findsOneWidget);
    expect(find.textContaining('EVK-MOCK'), findsOneWidget);
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text(formatRp(event.price + 2500)), findsOneWidget);
    expect(find.textContaining('GoPay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('satu tiket satu transaksi, diskon hanya di tiket pertama', (
    tester,
  ) async {
    final api = MockApiService();
    final event = await _seed(
      tester,
      api,
      qty: 2,
      voucherCode: 'EVENTKUY',
    );

    final transactions = await tester.runAsync(api.fetchTransactions);

    expect(transactions, isNotNull);
    expect(transactions!.length, 2);
    // Mock menyisipkan transaksi terbaru di depan: tiket kedua tanpa diskon,
    // tiket pertama memakai diskon voucher.
    expect(
      transactions.map((trx) => trx.total.round()).toList(),
      [event.price + 2500, event.price + 2500 - 25000],
    );
    expect(transactions.map((trx) => trx.ticketCode).toSet().length, 2);
  });

  testWidgets('error jaringan menampilkan state gagal', (tester) async {
    await tester.pumpWidget(_app(api: _FailingApi()));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat riwayat transaksi'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol coba lagi memenuhi target sentuh 48', (tester) async {
    await tester.pumpWidget(_app(api: _FailingApi()));
    await tester.pumpAndSettle();

    final retry = find.widgetWithText(OutlinedButton, 'Coba Lagi');
    expect(retry, findsOneWidget);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
