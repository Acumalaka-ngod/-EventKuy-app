import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/notification_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/services/mock_api_service.dart';

Widget _app({required EventProvider events, required MockApiService api}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
      ChangeNotifierProvider(
        create: (_) => TicketProvider(api: api, pollInterval: null),
      ),
      ChangeNotifierProvider(create: (_) => NotificationProvider(api: api)),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const MainNavigation()),
  );
}

Future<EventProvider> _loadedEvents(WidgetTester tester) async {
  final events = EventProvider(api: MockApiService());
  await tester.runAsync(() => events.loadEvents());
  return events;
}

void main() {
  group('Navbar mobile', () {
    testWidgets('full-width, menempel dasar layar, dan lebih besar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = await _loadedEvents(tester);

      await tester.pumpWidget(_app(events: events, api: api));
      await tester.pump();

      final bar = find.byKey(const ValueKey('mobile-nav-bar'));
      expect(bar, findsOneWidget);

      final rect = tester.getRect(bar);
      expect(rect.left, 0, reason: 'navbar harus menyentuh tepi kiri layar');
      expect(rect.right, 390, reason: 'navbar harus menyentuh tepi kanan layar');
      expect(rect.bottom, 844, reason: 'navbar harus menempel dasar layar');
      expect(
        rect.height,
        greaterThanOrEqualTo(78),
        reason: 'navbar mobile harus lebih besar dari versi lama (72)',
      );
    });

    testWidgets('border hanya di sisi atas, tanpa sudut membulat', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = await _loadedEvents(tester);

      await tester.pumpWidget(_app(events: events, api: api));
      await tester.pump();

      final bar = find.byKey(const ValueKey('mobile-nav-bar'));
      final container = tester.widget<Container>(bar);
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(border.top.width, greaterThan(0));
      expect(border.top.color, AppTheme.border);
      expect(border.left, BorderSide.none);
      expect(border.right, BorderSide.none);
      expect(border.bottom, BorderSide.none);
      expect(decoration.borderRadius, isNull);
      expect(decoration.color, AppTheme.surface);
    });

    testWidgets('setiap item punya target sentuh minimal 48x48', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = await _loadedEvents(tester);

      await tester.pumpWidget(_app(events: events, api: api));
      await tester.pump();

      const labels = ['Beranda', 'Jelajahi', 'Tiket', 'Favorit', 'Profil'];
      for (var i = 0; i < labels.length; i++) {
        final item = find.byKey(ValueKey('mobile-nav-item-$i'));
        expect(item, findsOneWidget);
        expect(
          find.descendant(of: item, matching: find.text(labels[i])),
          findsOneWidget,
        );

        final size = tester.getSize(item);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('item terpilih ditandai selected pada semantics', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = MockApiService();
      final events = await _loadedEvents(tester);

      await tester.pumpWidget(_app(events: events, api: api));
      await tester.pump();

      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('mobile-nav-item-0')),
          ),
          isSemantics(
            label: 'Beranda',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(find.text('Favorit'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('mobile-nav-item-3')),
          ),
          isSemantics(label: 'Favorit', isSelected: true),
        );
      } finally {
        semantics.dispose();
      }
    });
  });
}
