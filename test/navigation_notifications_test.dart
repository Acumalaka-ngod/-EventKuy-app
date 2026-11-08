import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/notification_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/ticket_item.dart';

Widget _app({required EventProvider events, required MockApiService api}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
      ChangeNotifierProvider(
        create: (_) => TicketProvider(api: api, pollInterval: null),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationProvider(api: api),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const MainNavigation()),
  );
}

void main() {
  testWidgets('rail tablet menampilkan ikon + label dan target 48', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    await tester.runAsync(() => events.loadEvents());

    await tester.pumpWidget(_app(events: events, api: api));
    await tester.pump(const Duration(milliseconds: 400));

    const labels = ['Beranda', 'Jelajahi', 'Tiket', 'Favorit', 'Profil'];
    for (var i = 0; i < labels.length; i++) {
      final item = find.byKey(ValueKey('rail-item-$i'));
      expect(item, findsOneWidget);
      expect(
        find.descendant(of: item, matching: find.text(labels[i])),
        findsOneWidget,
        reason: 'rail item ${labels[i]} tidak menampilkan label teks',
      );
      expect(tester.getSize(item).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(item).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('notifikasi membuka bottom sheet empty state tanpa badge palsu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    await tester.runAsync(() => events.loadEvents());

    await tester.pumpWidget(_app(events: events, api: api));
    await tester.pump();

    final semantics = tester.ensureSemantics();
    try {
      final notification = find.bySemanticsLabel('Notifikasi');
      expect(notification, findsOneWidget);
      expect(
        find.descendant(of: notification, matching: find.byType(Container)),
        findsNothing,
        reason: 'badge notifikasi palsu tidak boleh tampil',
      );

      await tester.tap(notification);
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Notifikasi'), findsOneWidget);
      expect(find.textContaining('tiket dan event'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'tiket attendee tidak punya tombol check-in, tampil instruksi QR',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: const TicketItem(
                ticket: Ticket(
                  code: 'EVK-TEST-001',
                  eventId: 'e1',
                  eventTitle: 'Konser Senja',
                  status: 'paid',
                ),
                dateLocation: '12 Juli 2025 · Istora Senayan',
                attendeeName: 'Siti Rahma',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Check-in Tiket'), findsNothing);
      expect(find.text('Tunjukkan QR ini ke petugas'), findsOneWidget);
    },
  );
}
