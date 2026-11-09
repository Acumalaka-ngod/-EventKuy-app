import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/event_status.dart';
import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

Widget _checkoutApp({
  required Event event,
  required EventProvider events,
  required TicketProvider tickets,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: events),
      ChangeNotifierProvider.value(value: tickets),
      ChangeNotifierProvider(
        create: (_) => FavoriteProvider(api: MockApiService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: CheckoutScreen(event: event),
    ),
  );
}

Widget _detailApp({required Event event, required EventProvider events}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: events),
      ChangeNotifierProvider(
        create: (_) => FavoriteProvider(api: MockApiService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: EventDetailScreen(event: event),
    ),
  );
}

Future<void> _fillBuyer(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Siti Rahma');
  await tester.enterText(find.byType(TextFormField).at(1), 'siti@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), '081234567890');
  await tester.pump();
}

/// API yang menahan fetch pertama sampai [release] dipanggil, supaya bisa
/// menguji permintaan force-refresh yang datang saat fetch masih berjalan.
class _GatedApi extends MockApiService {
  final _gate = Completer<void>();
  int fetchCalls = 0;

  @override
  Future<List<Event>> fetchEvents() async {
    fetchCalls++;
    if (fetchCalls == 1) await _gate.future;
    return super.fetchEvents();
  }

  void release() => _gate.complete();
}

void main() {
  group('EventProvider — stok real', () {
    test(
      'loadEvents(force: true) memuat ulang stok setelah checkout',
      () async {
        final api = MockApiService();
        final events = EventProvider(api: api);
        final tickets = TicketProvider(api: api, pollInterval: null);
        addTearDown(tickets.dispose);

        await events.loadEvents();
        final event = events.events.first;
        final before = event.sold;

        await tickets.checkout(event, qty: 2);

        // Tanpa force, provider masih memakai cache lama (perilaku lama).
        await events.loadEvents();
        expect(events.eventById(event.id)!.sold, before);

        // Dengan force, stok diambil ulang dari backend.
        await events.loadEvents(force: true);
        expect(events.eventById(event.id)!.sold, before + 2);
        expect(events.eventById(event.id)!.available, event.available! - 2);
      },
    );

    test('applySoldDelta langsung mengurangi sisa tiket', () async {
      final api = MockApiService();
      final events = EventProvider(api: api);
      await events.loadEvents();

      final event = events.events.first;
      final before = event.available!;

      events.applySoldDelta(event.id, 2);

      final updated = events.eventById(event.id)!;
      expect(updated.sold, event.sold + 2);
      expect(updated.available, before - 2);
    });

    test('applySoldDelta tidak melebihi kuota event', () async {
      final api = MockApiService();
      final events = EventProvider(api: api);
      await events.loadEvents();

      final event = events.events.first;
      events.applySoldDelta(event.id, 999999);

      final updated = events.eventById(event.id)!;
      expect(updated.sold, event.quota);
      expect(updated.available, 0);
      expect(updated.isSoldOut, isTrue);
    });

    test('applySoldDelta mengabaikan event yang tidak dikenal', () async {
      final events = EventProvider(api: MockApiService());
      await events.loadEvents();
      final before = events.events.map((e) => e.sold).toList();

      events.applySoldDelta('event-tidak-ada', 5);

      expect(events.events.map((e) => e.sold).toList(), before);
    });

    test(
      'force refresh saat fetch berjalan tetap dijalankan setelahnya',
      () async {
        final api = _GatedApi();
        final events = EventProvider(api: api);

        final first = events.loadEvents();
        await Future<void>.delayed(Duration.zero);
        expect(api.fetchCalls, 1);

        // Permintaan ini harus diantrekan, bukan dibuang.
        await events.loadEvents(force: true);

        api.release();
        await first;
        await Future<void>.delayed(Duration.zero);

        expect(api.fetchCalls, 2);
        expect(events.events, isNotEmpty);
      },
    );
  });

  group('Status event organizer', () {
    final now = DateTime(2026, 11, 9, 10);

    test('event masa lalu berstatus selesai', () {
      expect(
        eventStatusFor(DateTime(2026, 11, 8), now: now),
        EventStatus.finished,
      );
      expect(EventStatus.finished.label, 'Selesai');
    });

    test('event hari ini berstatus hari ini', () {
      expect(
        eventStatusFor(DateTime(2026, 11, 9), now: now),
        EventStatus.today,
      );
      expect(EventStatus.today.label, 'Hari Ini');
    });

    test('event mendatang berstatus akan datang', () {
      expect(
        eventStatusFor(DateTime(2026, 11, 10), now: now),
        EventStatus.upcoming,
      );
      expect(EventStatus.upcoming.label, 'Akan Datang');
    });
  });

  group('CheckoutScreen — sinkronisasi stok', () {
    testWidgets('stok provider berkurang setelah pembayaran berhasil', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = EventProvider(api: api);
      final tickets = TicketProvider(api: api, pollInterval: null);
      addTearDown(tickets.dispose);

      await tester.runAsync(() => events.loadEvents());
      final event = events.events.first;
      final before = event.sold;

      await tester.pumpWidget(
        _checkoutApp(event: event, events: events, tickets: tickets),
      );
      await tester.pump();

      await _fillBuyer(tester);
      await tester.tap(find.textContaining('Bayar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran Berhasil!'), findsOneWidget);
      expect(events.eventById(event.id)!.sold, before + 1);
      expect(events.eventById(event.id)!.available, event.available! - 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('EventDetailScreen — stok mengikuti provider', () {
    testWidgets('label sisa tiket ikut berubah saat stok diperbarui', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = EventProvider(api: api);
      await tester.runAsync(() => events.loadEvents());
      final event = events.events.first;

      await tester.pumpWidget(_detailApp(event: event, events: events));
      await tester.pump();

      expect(find.text('Sisa ${event.available} tiket'), findsOneWidget);

      events.applySoldDelta(event.id, 100);
      await tester.pump();

      expect(find.text('Sisa ${event.available! - 100} tiket'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
