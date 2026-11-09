import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/screens/organizer/organizer_dashboard_screen.dart';
import 'package:eventkuy/screens/scan/scan_screen.dart';
import 'package:eventkuy/screens/ticket/my_tickets_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _sizes = [
  Size(390, 844), // HP
  Size(768, 1024), // Tablet
  Size(1400, 900), // Desktop
];

Future<EventProvider> _loadedEventProvider(WidgetTester tester) async {
  final provider = EventProvider(api: MockApiService());
  await tester.runAsync(() => provider.loadEvents());
  return provider;
}

Widget _wrap({
  required Widget child,
  EventProvider? events,
  TicketProvider? tickets,
  AuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider(
        create: (_) => events ?? EventProvider(api: MockApiService()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            tickets ??
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
  group('EventDetailScreen — konten harus lengkap di semua ukuran', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final event = events.events.first;

        await tester.pumpWidget(
          _wrap(
            child: EventDetailScreen(event: event),
            events: events,
          ),
        );
        await tester.pump();

        // Konten WAJIB ada semua
        expect(find.text(event.title), findsOneWidget);
        expect(find.text(event.category.toUpperCase()), findsOneWidget); // chip
        expect(find.text('Tentang Acara'), findsOneWidget);
        expect(find.text(event.description), findsOneWidget);
        expect(find.text('Harga Tiket'), findsOneWidget);
        expect(find.text('Daftar & Beli Tiket'), findsOneWidget);

        // Bottom bar harus tetap tipis di bawah, bukan menutupi detail.
        final buyBar = tester.getSize(
          find.byKey(const ValueKey('event-detail-buy-bar')),
        );
        expect(buyBar.height, lessThan(160));
        expect(buyBar.width, size.width);
        expect(find.text(event.title).hitTestable(), findsOneWidget);

        expect(find.text('1 / ${event.galleryImages.length}'), findsOneWidget);
        expect(find.text('Istora Senayan'), findsOneWidget); // kartu lokasi
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('galeri foto bisa di-swipe dan counter ikut berubah', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final events = await _loadedEventProvider(tester);
      final event = events.events.first;

      await tester.pumpWidget(
        _wrap(
          child: EventDetailScreen(event: event),
          events: events,
        ),
      );
      await tester.pump();

      expect(event.galleryImages.length, greaterThan(1));
      expect(find.text('1 / ${event.galleryImages.length}'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-380, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 / ${event.galleryImages.length}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MyTicketsScreen — detail tiket lengkap + QR', () {
    for (final size in const [Size(390, 844), Size(1400, 900)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final tickets = TicketProvider(
          api: MockApiService(),
          pollInterval: null,
        );
        await tester.runAsync(() => tickets.checkout(events.events.first));

        await tester.pumpWidget(
          _wrap(
            child: const MyTicketsScreen(),
            events: events,
            tickets: tickets,
          ),
        );
        await tester.pump();

        expect(find.text('PEMILIK TIKET'), findsOneWidget);
        expect(find.text('TICKET ID'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Unduh PDF'), findsOneWidget);
        expect(find.text('Tunjukkan QR ini ke petugas'), findsOneWidget);
        expect(find.text('Check-in Tiket'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CheckoutScreen — form lengkap', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);
        final event = events.events.first;

        await tester.pumpWidget(
          _wrap(
            child: CheckoutScreen(event: event),
            events: events,
          ),
        );
        await tester.pump();

        expect(find.text('Informasi Pemesan'), findsOneWidget);
        expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);
        expect(find.text('Virtual Account'), findsOneWidget);
        expect(find.text('Kartu Kredit / Debit'), findsOneWidget);
        expect(find.text('Total Pembayaran'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.textContaining('Bayar Sekarang'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.textContaining('Bayar Sekarang'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ScanScreen — tidak boleh overflow (termasuk layar pendek)', () {
    for (final size in const [
      Size(390, 844),
      Size(1366, 620), // jendela Chrome pendek — kasus paling rawan
      Size(1024, 600),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);

        await tester.pumpWidget(
          _wrap(child: const ScanScreen(enableCamera: false), events: events),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Scan QR Code'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ScanScreen — check-in lewat kode manual', () {
    testWidgets('tiket berhasil di-check-in dan dialog sukses tampil', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final events = await _loadedEventProvider(tester);
      final tickets = TicketProvider(api: MockApiService(), pollInterval: null);
      late final Ticket ticket;
      await tester.runAsync(() async {
        ticket = (await tickets.checkout(events.events.first)).ticket;
      });

      await tester.pumpWidget(
        _wrap(
          child: const ScanScreen(enableCamera: false),
          events: events,
          tickets: tickets,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Masukkan Kode Manual'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Masukkan Kode Tiket'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ticket.code);
      await tester.tap(find.text('Check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Check-in Berhasil'), findsOneWidget);
      expect(tickets.tickets.single.status, 'checked_in');

      await tester.tap(find.text('Scan Lagi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Check-in Berhasil'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('OrganizerDashboard — statistik & menu lengkap', () {
    for (final size in const [Size(390, 844), Size(1400, 900)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
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

    testWidgets('hanya menampilkan event milik organizer yang login', (
      tester,
    ) async {
      final events = await _loadedEventProvider(tester);
      final auth = AuthProvider(
        initialUser: const AppUser(
          id: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
          name: 'Organizer Demo',
          email: 'eventkuy.organizer@gmail.com',
          role: 'organizer',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          child: const OrganizerDashboardScreen(),
          events: events,
          auth: auth,
        ),
      );
      await tester.pump();

      expect(find.text('Sound of Tomorrow'), findsOneWidget);
      expect(find.text('Total Peserta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menampilkan empty state jika organizer belum punya event', (
      tester,
    ) async {
      final events = await _loadedEventProvider(tester);
      final auth = AuthProvider(
        initialUser: const AppUser(
          id: '00000000-0000-4000-8000-000000000000',
          name: 'Organizer Baru',
          email: 'organizer.baru@example.com',
          role: 'organizer',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          child: const OrganizerDashboardScreen(),
          events: events,
          auth: auth,
        ),
      );
      await tester.pump();

      expect(find.text('Belum ada event yang dikelola'), findsOneWidget);
      expect(find.text('Total Peserta'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Beranda & semua tab (MainNavigation) — bebas overflow', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = await _loadedEventProvider(tester);

        await tester.pumpWidget(
          _wrap(child: const MainNavigation(), events: events),
        );
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump();

        // Topbar beranda selalu terlihat di semua breakpoint
        expect(find.text('Semua Kota'), findsOneWidget);
        if (size.width < 720) {
          expect(find.text('Beranda'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);

        for (final tab in const ['Jelajahi', 'Tiket', 'Favorit', 'Profil']) {
          final byText = find.text(tab);
          final finder = byText.evaluate().isNotEmpty
              ? byText.first
              : find.byTooltip(tab);
          await tester.tap(finder);
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            tester.takeException(),
            isNull,
            reason: 'Tab "$tab" overflow/exception di $size',
          );
        }
      });
    }
  });
}
