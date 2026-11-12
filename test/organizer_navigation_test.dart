import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/deep_link_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/notification_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/screens/scan/scan_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _organizer = AppUser(
  id: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
  name: 'Organizer Demo',
  email: 'eventkuy.organizer@gmail.com',
  role: 'organizer',
);

Widget _app({
  required EventProvider events,
  required MockApiService api,
  required AuthProvider auth,
  DeepLinkProvider? deepLinks,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<EventProvider>.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
      ChangeNotifierProvider(
        create: (_) => TicketProvider(api: api, pollInterval: null),
      ),
      ChangeNotifierProvider(create: (_) => NotificationProvider(api: api)),
      if (deepLinks != null)
        ChangeNotifierProvider<DeepLinkProvider>.value(value: deepLinks),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const MainNavigation(scanScreen: ScanScreen(enableCamera: false)),
    ),
  );
}

Future<EventProvider> _loadedEvents(WidgetTester tester) async {
  final events = EventProvider(api: MockApiService());
  await tester.runAsync(() => events.loadEvents());
  return events;
}

void _mobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'mobile organizer: dashboard jadi beranda, Scan QR besar di tengah, '
    'tanpa tab pembeli',
    (tester) async {
      _mobileSurface(tester);

      final api = MockApiService();
      final events = await _loadedEvents(tester);

      await tester.pumpWidget(
        _app(
          events: events,
          api: api,
          auth: AuthProvider(initialUser: _organizer),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Dashboard Event Organizer'), findsOneWidget);
      expect(find.text('Semua Kota'), findsNothing);

      final bar = find.byKey(const ValueKey('mobile-nav-bar'));
      expect(bar, findsOneWidget);

      expect(
        find.descendant(of: bar, matching: find.text('Beranda')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Scan QR')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Profil')),
        findsOneWidget,
      );

      for (final buyerTab in const ['Jelajahi', 'Tiket', 'Favorit']) {
        expect(
          find.descendant(of: bar, matching: find.text(buyerTab)),
          findsNothing,
          reason: 'Tab pembeli "$buyerTab" tidak boleh ada untuk organizer',
        );
      }

      final scan = find.byKey(const ValueKey('organizer-scan-action'));
      expect(scan, findsOneWidget);
      expect(tester.getSize(scan).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(scan).height, greaterThanOrEqualTo(48));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('aksi Scan QR organizer membuka ScanScreen', (tester) async {
    _mobileSurface(tester);

    final api = MockApiService();
    final events = await _loadedEvents(tester);

    await tester.pumpWidget(
      _app(
        events: events,
        api: api,
        auth: AuthProvider(initialUser: _organizer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('organizer-scan-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Scan QR Code'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard Event Organizer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab Profil organizer bebas dari fitur pembeli', (tester) async {
    _mobileSurface(tester);

    final api = MockApiService();
    final events = await _loadedEvents(tester);

    await tester.pumpWidget(
      _app(
        events: events,
        api: api,
        auth: AuthProvider(initialUser: _organizer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final bar = find.byKey(const ValueKey('mobile-nav-bar'));
    await tester.tap(find.descendant(of: bar, matching: find.text('Profil')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Tiket Saya'), findsNothing);
    expect(find.text('Riwayat Transaksi'), findsNothing);
    expect(find.text('MODE ORGANIZER'), findsNothing);
    expect(find.text('Edit Informasi Profil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet organizer: rail Beranda, Scan QR, Profil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = await _loadedEvents(tester);

    await tester.pumpWidget(
      _app(
        events: events,
        api: api,
        auth: AuthProvider(initialUser: _organizer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Dashboard Event Organizer'), findsOneWidget);
    expect(find.byKey(const ValueKey('organizer-scan-action')), findsOneWidget);

    final beranda = find.byKey(const ValueKey('rail-item-0'));
    final profil = find.byKey(const ValueKey('rail-item-1'));
    expect(beranda, findsOneWidget);
    expect(profil, findsOneWidget);
    expect(
      find.descendant(of: beranda, matching: find.text('Beranda')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profil, matching: find.text('Profil')),
      findsOneWidget,
    );

    // Organizer hanya punya dua tab, jadi tidak ada rail item ketiga.
    expect(find.byKey(const ValueKey('rail-item-2')), findsNothing);
    expect(find.text('Jelajahi'), findsNothing);
    expect(find.text('Favorit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop organizer: sidebar menonjolkan tombol Scan QR', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = await _loadedEvents(tester);

    await tester.pumpWidget(
      _app(
        events: events,
        api: api,
        auth: AuthProvider(initialUser: _organizer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Dashboard Event Organizer'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.byKey(const ValueKey('organizer-scan-action')), findsOneWidget);
    expect(find.text('Jelajahi'), findsNothing);
    expect(find.text('Favorit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deep link event tetap membuka Detail Event untuk pembeli', (
    tester,
  ) async {
    _mobileSurface(tester);

    final api = MockApiService();
    final events = await _loadedEvents(tester);
    final deepLinks = DeepLinkProvider()
      ..handleUri('eventkuy://event/${events.events.first.id}');

    await tester.pumpWidget(
      _app(
        events: events,
        api: api,
        auth: AuthProvider(
          initialUser: const AppUser(
            id: 'u1',
            name: 'Siti Rahma',
            email: 'siti@example.com',
          ),
        ),
        deepLinks: deepLinks,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(deepLinks.hasPending, isFalse);
    expect(find.text('Daftar & Beli Tiket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deep link event dikonsumsi tanpa membuka detail untuk organizer',
    (tester) async {
      _mobileSurface(tester);

      final api = MockApiService();
      final events = await _loadedEvents(tester);
      final deepLinks = DeepLinkProvider()
        ..handleUri('eventkuy://event/${events.events.first.id}');

      await tester.pumpWidget(
        _app(
          events: events,
          api: api,
          auth: AuthProvider(initialUser: _organizer),
          deepLinks: deepLinks,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(deepLinks.hasPending, isFalse);
      expect(find.text('Daftar & Beli Tiket'), findsNothing);
      expect(find.text('Dashboard Event Organizer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
