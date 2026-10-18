import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ajangin/core/theme.dart';
import 'package:ajangin/providers/auth_provider.dart';
import 'package:ajangin/providers/event_provider.dart';
import 'package:ajangin/providers/favorite_provider.dart';
import 'package:ajangin/providers/ticket_provider.dart';
import 'package:ajangin/screens/checkout/checkout_screen.dart';
import 'package:ajangin/screens/event/event_detail_screen.dart';
import 'package:ajangin/screens/main_navigation.dart';
import 'package:ajangin/screens/organizer/organizer_dashboard_screen.dart';
import 'package:ajangin/screens/scan/scan_screen.dart';
import 'package:ajangin/screens/ticket/my_tickets_screen.dart';

const _sizes = [
  Size(390, 844), // HP
  Size(768, 1024), // Tablet
  Size(1400, 900), // Desktop
];

Future<EventProvider> _loadedEventProvider(WidgetTester tester) async {
  final provider = EventProvider();
  await tester.runAsync(() => provider.loadEvents());
  return provider;
}

Widget _wrap({
  required Widget child,
  EventProvider? events,
  TicketProvider? tickets,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => events ?? EventProvider()),
      ChangeNotifierProvider(create: (_) => tickets ?? TicketProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EventDetailScreen — konten harus lengkap di semua ukuran', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final event = events.events.first;

        await tester.pumpWidget(
          _wrap(child: EventDetailScreen(event: event), events: events),
        );
        await tester.pump();

        // Konten WAJIB ada semua
        expect(find.text(event.title), findsOneWidget);
        expect(find.text(event.category), findsOneWidget); // chip kategori
        expect(find.text('Tentang Event'), findsOneWidget);
        expect(find.text(event.description), findsOneWidget);
        expect(find.text('Mulai dari'), findsOneWidget);
        expect(find.text('Daftar Sekarang'), findsOneWidget);
        expect(find.text('1/5'), findsOneWidget);
        expect(find.text('Istora Senayan'), findsOneWidget); // kartu lokasi
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MyTicketsScreen — detail tiket lengkap + QR', () {
    for (final size in const [Size(390, 844), Size(1400, 900)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final tickets = TicketProvider()..buyDummy(events.events.first);

        await tester.pumpWidget(
          _wrap(
            child: const MyTicketsScreen(),
            events: events,
            tickets: tickets,
          ),
        );
        await tester.pump();

        expect(find.text('Nama Peserta'), findsOneWidget);
        expect(find.text('Kategori'), findsOneWidget);
        expect(find.text('No. Tiket'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Simpan ke Galeri'), findsOneWidget);
        expect(find.text('Lihat Detail Event'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CheckoutScreen — form lengkap', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final event = events.events.first;

        await tester.pumpWidget(
          _wrap(child: CheckoutScreen(event: event), events: events),
        );
        await tester.pump();

        expect(find.text('Data Peserta'), findsOneWidget);
        expect(find.text('Metode Pembayaran'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);
        expect(find.text('Virtual Account'), findsOneWidget);
        expect(find.text('Kartu Kredit / Debit'), findsOneWidget);
        expect(find.text('Total Pembayaran'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Bayar Sekarang'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.text('Bayar Sekarang'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ScanScreen — tidak boleh overflow (termasuk layar pendek)',
      () {
    for (final size in const [
      Size(390, 844),
      Size(1366, 620), // jendela Chrome pendek — kasus paling rawan
      Size(1024, 600),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);

        await tester.pumpWidget(
          _wrap(child: const ScanScreen(), events: events),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Scan QR Code'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('OrganizerDashboard — statistik & menu lengkap', () {
    for (final size in const [Size(390, 844), Size(1400, 900)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);

        await tester.pumpWidget(
          _wrap(child: const OrganizerDashboardScreen(), events: events),
        );
        await tester.pump();

        expect(find.text('Dashboard Event Organizer'), findsOneWidget);
        expect(find.text('Total Peserta'), findsOneWidget);
        expect(find.text('Check-in'), findsOneWidget);
        expect(find.text('Tiket Terjual'), findsOneWidget);
        expect(find.text('Kelola Event'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Beranda & semua tab (MainNavigation) — bebas overflow', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_wrap(child: const MainNavigation()));
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump();

        expect(find.text('Event Terdekat'), findsOneWidget);
        expect(find.text('Lihat Semua'), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(tester.takeException(), isNull);

        for (final tab in const ['Jelajahi', 'Tiket', 'Favorit', 'Profil']) {
          await tester.tap(find.text(tab));
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull,
              reason: 'Tab "$tab" overflow/exception di $size');
        }
      });
    }
  });
}
