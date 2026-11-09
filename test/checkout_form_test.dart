import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/checkout_result.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/form_error_banner.dart';

Future<Event> _firstEvent(WidgetTester tester) async {
  late Event event;
  await tester.runAsync(() async {
    final events = await MockApiService().fetchEvents();
    event = events.first;
  });
  return event;
}

Widget _app(Event event, {AuthProvider? auth, TicketProvider? tickets}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider(
        create: (_) => EventProvider(api: MockApiService()),
      ),
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

class _FailingTicketProvider extends TicketProvider {
  _FailingTicketProvider() : super(api: MockApiService(), pollInterval: null);

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
    throw StateError('Stok tiket habis.');
  }
}

Future<void> _fillValidBuyer(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Siti Rahma');
  await tester.enterText(find.byType(TextFormField).at(1), 'siti@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), '081234567890');
  await tester.pump();
}

void main() {
  group('Data pemesan', () {
    testWidgets('tidak memakai data palsu saat user belum login', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, greaterThanOrEqualTo(3));
      final buyerFields = fields.take(3).toList();
      for (final field in buyerFields) {
        expect(field.controller?.text ?? '', isEmpty);
      }

      expect(find.text('Andi Pratama'), findsNothing);
      expect(find.text('andi@eventkuy.id'), findsNothing);
      expect(find.text('0812 3456 7890'), findsNothing);
    });

    testWidgets('field punya autofill hint yang sesuai', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.length, greaterThanOrEqualTo(3));
      expect(fields[0].autofillHints, contains(AutofillHints.name));
      expect(fields[1].autofillHints, contains(AutofillHints.email));
      expect(fields[2].autofillHints, contains(AutofillHints.telephoneNumber));
    });
  });

  group('Validasi form', () {
    testWidgets('field kosong menampilkan error inline', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Nomor HP wajib diisi.'), findsOneWidget);
    });

    testWidgets('email dan nomor HP tidak valid ditolak inline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'Siti');
      await tester.enterText(find.byType(TextFormField).at(1), 'siti@');
      await tester.enterText(find.byType(TextFormField).at(2), '0812');
      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid.'), findsOneWidget);
      expect(find.text('Nomor HP tidak valid.'), findsOneWidget);
    });

    testWidgets('error API tampil inline, bukan hanya SnackBar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event, tickets: _FailingTicketProvider()));
      await tester.pump();

      await _fillValidBuyer(tester);
      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.byType(FormErrorBanner), findsOneWidget);
      expect(find.text('Stok tiket habis.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Layout checkout', () {
    for (final size in const [Size(390, 844), Size(768, 1024)]) {
      testWidgets('CTA sticky terlihat tanpa menggulir di '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final event = await _firstEvent(tester);
        await tester.pumpWidget(_app(event));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('checkout-sticky-bar')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Bayar Sekarang').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('1400 memakai dua kolom tanpa sticky bar', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = await _firstEvent(tester);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      expect(find.byKey(const ValueKey('checkout-sticky-bar')), findsNothing);
      expect(
        find.textContaining('Bayar Sekarang').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
