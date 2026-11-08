import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/favorite/favorite_screen.dart';
import 'package:eventkuy/screens/ticket/my_tickets_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart';
import 'package:eventkuy/widgets/ticket_item.dart';

class _FlakyApi extends MockApiService {
  bool failFavorites = false;
  bool failTickets = false;
  List<Ticket> tickets = [];

  @override
  Future<Set<String>> fetchFavoriteIds() async {
    if (failFavorites) throw StateError('Gagal memuat favorit.');
    return super.fetchFavoriteIds();
  }

  @override
  Future<List<Ticket>> fetchTickets() async {
    if (failTickets) throw StateError('Gagal memuat tiket.');
    return List.of(tickets);
  }
}

class _FailAddFavoriteApi extends MockApiService {
  @override
  Future<void> addFavorite(String eventId) async {
    throw StateError('Gagal menyimpan favorit.');
  }
}

void main() {
  group('TicketProvider', () {
    test('load gagal menyimpan error dan retry membersihkannya', () async {
      final api = _FlakyApi()..failTickets = true;
      final provider = TicketProvider(api: api, pollInterval: null);

      await provider.load();
      expect(provider.error, 'Gagal memuat tiket.');
      expect(provider.loading, isFalse);
      expect(provider.tickets, isEmpty);

      api.failTickets = false;
      await provider.load();
      expect(provider.error, isNull);
    });

    test('load berhasil mengisi tiket dan menghapus error lama', () async {
      final api = _FlakyApi()..failTickets = true;
      final provider = TicketProvider(api: api, pollInterval: null);

      await provider.load();
      expect(provider.error, isNotNull);

      api
        ..failTickets = false
        ..tickets = [
          const Ticket(
            code: 'EVK-1',
            eventId: 'e1',
            eventTitle: 'Konser Senja',
            status: 'paid',
          ),
        ];

      await provider.load();
      expect(provider.error, isNull);
      expect(provider.tickets.single.code, 'EVK-1');
    });
  });

  group('FavoriteProvider', () {
    test('load gagal menyimpan error dan retry berhasil', () async {
      final api = _FlakyApi()..failFavorites = true;
      await api.addFavorite('e1');
      final provider = FavoriteProvider(api: api);

      await provider.load();
      expect(provider.error, 'Gagal memuat favorit.');
      expect(provider.loading, isFalse);
      expect(provider.ids, isEmpty);

      api.failFavorites = false;
      await provider.load();
      expect(provider.error, isNull);
      expect(provider.ids, {'e1'});
    });

    test('toggle rollback saat API gagal', () async {
      final provider = FavoriteProvider(api: _FailAddFavoriteApi());

      await provider.toggle('e1');
      expect(provider.isFav('e1'), isFalse);
    });

    test(
      'clearFavorites mengosongkan dan restoreFavorites mengembalikan',
      () async {
        final api = MockApiService();
        final provider = FavoriteProvider(api: api);

        await provider.toggle('e1');
        await provider.toggle('e2');

        await provider.clearFavorites();
        expect(provider.ids, isEmpty);

        await provider.restoreFavorites(['e1', 'e2']);
        expect(provider.ids, {'e1', 'e2'});
      },
    );
  });

  group('FavoriteScreen', () {
    testWidgets('load gagal menampilkan error + Coba Lagi, lalu pulih', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = _FlakyApi()..failFavorites = true;
      final events = EventProvider(api: api);
      final fav = FavoriteProvider(api: api);
      await tester.runAsync(() async {
        await events.loadEvents();
        await api.addFavorite(events.events[0].id);
        await fav.load();
      });
      expect(fav.error, isNotNull);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: events),
            ChangeNotifierProvider.value(value: fav),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const FavoriteScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Gagal Memuat Favorit'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Belum Ada Favorit'), findsNothing);

      api.failFavorites = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(EventGridCard), findsOneWidget);
    });

    testWidgets('Hapus Semua minta konfirmasi dan bisa diurungkan', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = EventProvider(api: api);
      final fav = FavoriteProvider(api: api);
      await tester.runAsync(() async {
        await events.loadEvents();
        await fav.load();
        await fav.toggle(events.events[0].id);
        await fav.toggle(events.events[1].id);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: events),
            ChangeNotifierProvider.value(value: fav),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const FavoriteScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EventGridCard), findsNWidgets(2));

      await tester.tap(find.widgetWithText(TextButton, 'Hapus Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Semua Favorit?'), findsOneWidget);
      expect(find.textContaining('2 event'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(EventGridCard), findsNWidgets(2));

      await tester.tap(find.widgetWithText(TextButton, 'Hapus Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.byType(EventGridCard), findsNothing);
      expect(find.text('Urungkan'), findsOneWidget);
      expect(fav.ids, isEmpty);

      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle();

      expect(fav.ids.length, 2);
      expect(find.byType(EventGridCard), findsNWidgets(2));
    });
  });

  group('MyTicketsScreen', () {
    testWidgets('load gagal menampilkan error + Coba Lagi, bukan empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = _FlakyApi()..failTickets = true;
      final events = EventProvider(api: api);
      final tickets = TicketProvider(api: api, pollInterval: null);
      await tester.runAsync(() => events.loadEvents());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: events),
            ChangeNotifierProvider.value(value: tickets),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MyTicketsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Tiket'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Belum Ada Tiket'), findsNothing);

      api
        ..failTickets = false
        ..tickets = [
          Ticket(
            code: 'EVK-1',
            eventId: events.events[0].id,
            eventTitle: events.events[0].title,
            status: 'paid',
          ),
        ];

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(TicketItem), findsOneWidget);
    });
  });
}
