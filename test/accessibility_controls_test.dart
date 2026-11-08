import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/checkout/checkout_screen.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/app_icon_button.dart';
import 'package:eventkuy/widgets/app_search_bar.dart';

const _user = AppUser(id: 'u1', name: 'Siti Rahma', email: 'siti@example.com');

Future<Event> _firstEvent(WidgetTester tester) async {
  late Event event;
  await tester.runAsync(() async {
    final events = await MockApiService().fetchEvents();
    event = events.first;
  });
  return event;
}

Widget _checkoutApp(Event event) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(initialUser: _user)),
      ChangeNotifierProvider(
        create: (_) =>
            TicketProvider(api: MockApiService(), pollInterval: null),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: CheckoutScreen(event: event),
    ),
  );
}

Widget _detailApp(Event event) {
  return MultiProvider(
    providers: [
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

void main() {
  group('AppIconButton', () {
    testWidgets('punya label semantics, tooltip, target 48, dan bisa ditekan', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var tapped = 0;

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: AppIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Kembali',
                onPressed: () => tapped++,
              ),
            ),
          ),
        );

        final finder = find.bySemanticsLabel('Kembali');
        expect(finder, findsOneWidget);
        expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        expect(find.byTooltip('Kembali'), findsOneWidget);

        await tester.tap(finder);
        await tester.pump();
        expect(tapped, 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('bisa diaktifkan lewat keyboard', (tester) async {
      var tapped = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: AppIconButton(
                icon: Icons.ios_share_rounded,
                label: 'Bagikan event',
                onPressed: () => tapped++,
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('status selected memakai label dan semantics terpilih', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: AppIconButton(
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                label: 'Simpan ke favorit',
                selectedLabel: 'Hapus dari favorit',
                selected: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Hapus dari favorit'), findsOneWidget);
        final node = tester.getSemantics(
          find.bySemanticsLabel('Hapus dari favorit'),
        );
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Tombol ikon layar', () {
    testWidgets('checkout memakai tombol kembali berlabel dan 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final event = await _firstEvent(tester);
        await tester.pumpWidget(_checkoutApp(event));
        await tester.pump();

        final back = find.bySemanticsLabel('Kembali');
        expect(back, findsOneWidget);
        expect(tester.getSize(back).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('detail event punya tombol kembali, bagikan, dan favorit 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final event = await _firstEvent(tester);
        await tester.pumpWidget(_detailApp(event));
        await tester.pump();

        for (final label in const [
          'Kembali',
          'Bagikan event',
          'Simpan ke favorit',
        ]) {
          final finder = find.bySemanticsLabel(label);
          expect(finder, findsOneWidget, reason: 'label "$label" tidak ada');
          expect(
            tester.getSize(finder).width,
            greaterThanOrEqualTo(48),
            reason: 'target "$label" terlalu kecil',
          );
          expect(
            tester.getSize(finder).height,
            greaterThanOrEqualTo(48),
            reason: 'target "$label" terlalu kecil',
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('filter dan clear pencarian berlabel serta target 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: AppSearchBar(onChanged: (_) {}, onFilterTap: () {}),
            ),
          ),
        );

        final filter = find.bySemanticsLabel('Filter lokasi');
        expect(filter, findsOneWidget);
        expect(tester.getSize(filter).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(filter).height, greaterThanOrEqualTo(48));

        await tester.enterText(find.byType(TextField), 'konser');
        await tester.pump();

        final clear = find.bySemanticsLabel('Hapus pencarian');
        expect(clear, findsOneWidget);
        expect(tester.getSize(clear).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(clear).height, greaterThanOrEqualTo(48));
      } finally {
        semantics.dispose();
      }
    });
  });
}
