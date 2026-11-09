import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/custom_button.dart';
import 'package:eventkuy/widgets/event_card.dart';

Event _event({int quota = 100, int sold = 0}) {
  return Event(
    id: '11111111-1111-4111-8111-000000000001',
    title: 'Sound of Tomorrow',
    description: 'Festival musik terbesar tahun ini.',
    date: DateTime(2025, 7, 12),
    location: 'Istora Senayan, Jakarta',
    price: 750000,
    quota: quota,
    sold: sold,
    imageUrl: 'assets/images/event_sound.jpg',
    category: 'Konser',
    tags: const ['Musik'],
    timeRange: '15:00 - 23:00',
  );
}

Widget _wrap(Widget child, {EventProvider? events, TicketProvider? tickets}) {
  final eventProvider = events ?? EventProvider(api: MockApiService());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: eventProvider),
      tickets != null
          ? ChangeNotifierProvider.value(value: tickets)
          : ChangeNotifierProvider(
              create: (_) =>
                  TicketProvider(api: MockApiService(), pollInterval: null),
            ),
      ChangeNotifierProvider(
        create: (_) => FavoriteProvider(api: MockApiService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

void main() {
  group('Event — status stok', () {
    test('sisa tiket dihitung dari kuota dikurangi terjual', () {
      final event = _event(quota: 50, sold: 12);
      expect(event.available, 38);
      expect(event.isSoldOut, isFalse);
    });

    test('event tanpa batas kuota tidak pernah habis', () {
      final event = _event(quota: 0, sold: 99);
      expect(event.available, isNull);
      expect(event.isSoldOut, isFalse);
    });

    test('event habis saat seluruh kuota terjual', () {
      final event = _event(quota: 50, sold: 50);
      expect(event.available, 0);
      expect(event.isSoldOut, isTrue);
    });

    test('sold dari JSON Supabase dipakai sebagai stok terjual', () {
      final event = Event.fromJson({
        'id': 'x',
        'title': 'Konser',
        'date': '2025-07-12T00:00:00',
        'location': 'Jakarta',
        'price': 100000,
        'quota': 10,
        'image_url': '',
        'category': 'Konser',
        'sold': 10,
      });
      expect(event.isSoldOut, isTrue);
    });
  });

  group('Thumbnail — label "Tiket Habis"', () {
    testWidgets('kartu grid menampilkan label saat tiket habis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                height: 320,
                child: EventGridCard(
                  event: _event(quota: 50, sold: 50),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tiket Habis'), findsOneWidget);
    });

    testWidgets('kartu list menampilkan label saat tiket habis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: EventCard(
                  event: _event(quota: 50, sold: 50),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tiket Habis'), findsOneWidget);
    });

    testWidgets('label tidak muncul saat stok masih ada', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                height: 320,
                child: EventGridCard(
                  event: _event(quota: 50, sold: 49),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tiket Habis'), findsNothing);
    });
  });

  group('Detail event — tombol beli saat tiket habis', () {
    testWidgets('tombol dinonaktifkan dan berlabel Tiket Habis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Provider dibiarkan kosong agar layar memakai snapshot widget yang
      // memang sudah habis; ID event mock bisa bertabrakan dengan snapshot.
      final events = EventProvider(api: MockApiService());

      await tester.pumpWidget(
        _wrap(
          EventDetailScreen(event: _event(quota: 50, sold: 50)),
          events: events,
        ),
      );
      await tester.pump();

      final buyButton = tester.widget<CustomButton>(
        find.widgetWithText(CustomButton, 'Tiket Habis'),
      );
      expect(buyButton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('Checkout — jumlah tiket & stok', () {
    testWidgets('tombol + menambah qty dan memperbarui total', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(CheckoutScreen(event: _event(quota: 10))));
      await tester.pump();

      // 1 tiket: Rp 750.000 + biaya layanan Rp 2.500.
      expect(find.text('Rp 752.500'), findsOneWidget);
      expect(find.text('Harga Tiket (1x)'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Harga Tiket (2x)'), findsOneWidget);
      expect(find.text('Biaya Layanan (2x)'), findsOneWidget);
      expect(find.text('Rp 1.505.000'), findsOneWidget);
    });

    testWidgets('tombol + berhenti di sisa stok', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Kuota 12, terjual 10 -> sisa 2 tiket.
      await tester.pumpWidget(
        _wrap(CheckoutScreen(event: _event(quota: 12, sold: 10))),
      );
      await tester.pump();

      expect(find.text('Sisa 2 tiket'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Harga Tiket (2x)'), findsOneWidget);
      expect(find.text('Harga Tiket (3x)'), findsNothing);
    });

    testWidgets('checkout event habis menonaktifkan tombol bayar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(CheckoutScreen(event: _event(quota: 50, sold: 50))),
      );
      await tester.pump();

      expect(find.text('Tiket habis — tidak bisa dibeli'), findsOneWidget);

      final payButton = tester.widget<CustomButton>(
        find.widgetWithText(CustomButton, 'Tiket Habis'),
      );
      expect(payButton.onPressed, isNull);
    });
  });

  group('Checkout — voucher sekali pakai', () {
    testWidgets('voucher yang sudah dipakai menampilkan pesan', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final tickets = TicketProvider(api: api, pollInterval: null);
      addTearDown(tickets.dispose);

      await tester.runAsync(() async {
        final events = await api.fetchEvents();
        await tickets.checkout(events.first, voucherCode: 'EVENTKUY');
      });

      await tester.pumpWidget(
        _wrap(CheckoutScreen(event: _event(quota: 10)), tickets: tickets),
      );
      await tester.pump();

      // TextField terakhir di layar checkout adalah kolom voucher.
      await tester.ensureVisible(find.text('Pakai'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'EVENTKUY');
      await tester.tap(find.text('Pakai'));
      await tester.pumpAndSettle();

      expect(find.textContaining('sudah pernah kamu pakai'), findsOneWidget);
    });
  });
}
