import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/ticket/my_tickets_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

/// Skenario: organizer melakukan check-in di perangkat lain. Tiket milik
/// attendee harus ikut ter-update tanpa reload manual.
void main() {
  group('TicketProvider - pantau perubahan tiket', () {
    test('tiket otomatis ter-refresh setelah organizer check-in', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final events = await api.fetchEvents();
      final ticket = await provider.checkout(events.first);

      provider.startWatching();
      // Sisi organizer: check-in lewat kode tiket.
      await api.checkIn(ticket.code);
      // Tunggu debounce 300 ms + pembacaan ulang data.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(provider.tickets.single.status, 'checked_in');
      expect(provider.lastCheckIn?.code, ticket.code);

      provider.acknowledgeCheckIn();
      expect(provider.lastCheckIn, isNull);
    });

    test('notifikasi tidak muncul untuk tiket yang sudah checked_in', () async {
      final api = MockApiService();
      final provider = TicketProvider(api: api, pollInterval: null);
      addTearDown(provider.dispose);

      final events = await api.fetchEvents();
      final ticket = await provider.checkout(events.first);
      await api.checkIn(ticket.code);
      // Muat awal: tiket sudah checked_in sebelum dipantau.
      await provider.load();

      provider.startWatching();
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(provider.lastCheckIn, isNull);
    });
  });

  testWidgets('MyTicketsScreen menampilkan notifikasi check-in berhasil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final tickets = TicketProvider(api: api, pollInterval: null);
    final events = EventProvider(api: api);
    late final Ticket ticket;
    await tester.runAsync(() async {
      await events.loadEvents();
      ticket = await tickets.checkout(events.events.first);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: tickets),
          ChangeNotifierProvider(
            create: (_) => FavoriteProvider(api: MockApiService()),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const MyTicketsScreen()),
      ),
    );
    await tester.pump();

    // Organizer check-in di perangkat lain.
    await tester.runAsync(() => api.checkIn(ticket.code));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();

    expect(find.text('Check-in berhasil — ${ticket.code}'), findsOneWidget);
  });
}
