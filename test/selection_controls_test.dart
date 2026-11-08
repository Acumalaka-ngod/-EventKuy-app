import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/screens/explore/explore_screen.dart';
import 'package:eventkuy/screens/ticket/my_tickets_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/category_chip.dart';
import 'package:eventkuy/widgets/event_card.dart';
import 'package:eventkuy/widgets/hero_banner.dart';
import 'package:eventkuy/widgets/payment_option.dart';
import 'package:eventkuy/widgets/section_header.dart';
import 'package:eventkuy/widgets/ticket_item.dart';

const _user = AppUser(id: 'u1', name: 'Siti Rahma', email: 'siti@example.com');

Future<Event> _firstEvent(WidgetTester tester) async {
  late Event event;
  await tester.runAsync(() async {
    final events = await MockApiService().fetchEvents();
    event = events.first;
  });
  return event;
}

void main() {
  group('Hati favorit di kartu event', () {
    testWidgets('berlabel, target 48, dan berubah saat ditekan', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final event = await _firstEvent(tester);
        final fav = FavoriteProvider(api: MockApiService());

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: fav,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 220,
                    height: 360,
                    child: EventGridCard(event: event, onTap: () {}),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final save = find.bySemanticsLabel('Simpan ke favorit');
        expect(save, findsOneWidget);
        expect(tester.getSize(save).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(save).height, greaterThanOrEqualTo(48));

        await tester.tap(save);
        await tester.pump();

        expect(find.bySemanticsLabel('Hapus dari favorit'), findsOneWidget);
        expect(fav.isFav(event.id), isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Opsi pembayaran', () {
    testWidgets('mengumumkan label, selected, dan target 48', (tester) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: PaymentOption(
                label: 'GoPay',
                subtitle: 'Saldo & QRIS instan',
                avatar: 'G',
                selected: true,
                onTap: () => tapped++,
              ),
            ),
          ),
        );

        final option = find.bySemanticsLabel('GoPay, Saldo & QRIS instan');
        expect(option, findsOneWidget);
        expect(tester.getSize(option).height, greaterThanOrEqualTo(48));

        final node = tester.getSemantics(option);
        expect(node.flagsCollection.isSelected, Tristate.isTrue);

        await tester.tap(option);
        await tester.pump();
        expect(tapped, 1);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Tombol jumlah tiket checkout', () {
    testWidgets('tambah/kurangi berlabel, target 48, dan disabled saat batas', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final event = await _firstEvent(tester);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AuthProvider(initialUser: _user),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    TicketProvider(api: MockApiService(), pollInterval: null),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: CheckoutScreen(event: event),
            ),
          ),
        );
        await tester.pump();

        final add = find.bySemanticsLabel('Tambah jumlah tiket');
        final remove = find.bySemanticsLabel('Kurangi jumlah tiket');
        expect(add, findsOneWidget);
        expect(remove, findsOneWidget);
        expect(tester.getSize(add).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));

        // Qty awal 1: tombol kurang disabled.
        expect(
          tester.getSemantics(remove).flagsCollection.isEnabled,
          Tristate.isFalse,
        );

        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(find.text('Harga Tiket (2x)'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Section header', () {
    testWidgets('Lihat Semua punya target minimal 48', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SectionHeader(title: 'Event Terdekat', onSeeAll: () {}),
            ),
          ),
        );

        final button = find.widgetWithText(TextButton, 'Lihat Semua');
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Chip kategori', () {
    testWidgets('CategoryChip berlabel, selected, dan target 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: CategoryChip(
                  label: 'Konser',
                  selected: true,
                  onTap: () => tapped++,
                ),
              ),
            ),
          ),
        );

        final chip = find.bySemanticsLabel('Konser');
        expect(chip, findsOneWidget);
        expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(chip).flagsCollection.isSelected,
          Tristate.isTrue,
        );

        await tester.tap(chip);
        await tester.pump();
        expect(tapped, 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('CategoryIconItem berlabel, selected, dan target 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: CategoryIconItem(
                  label: 'Seminar',
                  selected: false,
                  onTap: () => tapped++,
                ),
              ),
            ),
          ),
        );

        final item = find.bySemanticsLabel('Seminar');
        expect(item, findsOneWidget);
        expect(tester.getSize(item).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(item).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(item).flagsCollection.isSelected,
          Tristate.isFalse,
        );

        await tester.tap(item);
        await tester.pump();
        expect(tapped, 1);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Quick filter Jelajahi', () {
    testWidgets('berlabel, selected, dan target 48', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final events = EventProvider(api: MockApiService());
        await tester.runAsync(() => events.loadEvents());

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<EventProvider>.value(value: events),
              ChangeNotifierProvider(
                create: (_) => FavoriteProvider(api: MockApiService()),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const ExploreScreen(),
            ),
          ),
        );
        await tester.pump();

        final popular = find.bySemanticsLabel('Terpopuler');
        expect(popular, findsOneWidget);
        expect(tester.getSize(popular).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(popular).flagsCollection.isSelected,
          Tristate.isFalse,
        );

        await tester.tap(popular);
        await tester.pumpAndSettle();

        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Terpopuler'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Tab tiket', () {
    testWidgets('mengumumkan label + jumlah + selected dan target 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final api = MockApiService();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AuthProvider(initialUser: _user),
              ),
              ChangeNotifierProvider(create: (_) => EventProvider(api: api)),
              ChangeNotifierProvider(
                create: (_) => TicketProvider(api: api, pollInterval: null),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const MyTicketsScreen(),
            ),
          ),
        );
        await tester.pump();

        final all = find.bySemanticsLabel('Semua, 0 tiket');
        expect(all, findsOneWidget);
        expect(tester.getSize(all).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(all).flagsCollection.isSelected,
          Tristate.isTrue,
        );

        final done = find.bySemanticsLabel('Selesai, 0 tiket');
        expect(done, findsOneWidget);
        expect(tester.getSize(done).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(done).flagsCollection.isSelected,
          Tristate.isFalse,
        );

        await tester.ensureVisible(done);
        await tester.pumpAndSettle();
        await tester.tap(done);
        await tester.pumpAndSettle();

        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Selesai, 0 tiket'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Hero banner', () {
    testWidgets('berlabel, bisa diketuk, dan bisa diaktifkan lewat keyboard', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final event = await _firstEvent(tester);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: HeroBanner(event: event, onTap: () => tapped++),
            ),
          ),
        );
        await tester.pump();

        final hero = find.bySemanticsLabel('Lihat detail ${event.title}');
        expect(hero, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(tapped, 1, reason: 'hero tidak merespons keyboard');

        await tester.tap(hero);
        await tester.pump();
        expect(tapped, 2);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Aksi tiket', () {
    const ticket = Ticket(
      code: 'EVK-TEST-001',
      eventId: 'e1',
      eventTitle: 'Konser Senja',
      status: 'paid',
    );

    Widget ticketApp({VoidCallback? onViewDetail}) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TicketItem(
              ticket: ticket,
              dateLocation: '12 Juli 2025 · Istora Senayan',
              attendeeName: 'Siti Rahma',
              onViewDetail: onViewDetail,
            ),
          ),
        ),
      );
    }

    testWidgets('judul tiket berlabel dan bisa diaktifkan lewat keyboard', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;
      try {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ticketApp(onViewDetail: () => tapped++));
        await tester.pump();

        final title = find.bySemanticsLabel('Lihat detail Konser Senja');
        expect(title, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(tapped, 1, reason: 'judul tiket tidak merespons keyboard');

        await tester.tap(title);
        await tester.pump();
        expect(tapped, 2);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('tombol Unduh PDF punya target minimal 48', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ticketApp());
        await tester.pump();

        final download = find.widgetWithText(TextButton, 'Unduh PDF');
        expect(download, findsOneWidget);
        expect(tester.getSize(download).height, greaterThanOrEqualTo(48));
      } finally {
        semantics.dispose();
      }
    });
  });
}
