import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _user = AppUser(id: 'u1', name: 'Siti Rahma', email: 'siti@example.com');

Widget _app({required EventProvider events, required MockApiService api}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(initialUser: _user)),
      ChangeNotifierProvider<EventProvider>.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
      ChangeNotifierProvider(
        create: (_) => TicketProvider(api: api, pollInterval: null),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const MainNavigation()),
  );
}

void main() {
  testWidgets('pencarian Beranda dan Jelajahi memakai satu sumber kebenaran', (
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

    await tester.enterText(find.byType(TextField), 'konser');
    await tester.pump();
    expect(events.query, 'konser');

    await tester.tap(find.text('Jelajahi'));
    await tester.pumpAndSettle();

    final exploreField = tester.widget<TextField>(find.byType(TextField));
    expect(exploreField.controller?.text, 'konser');

    await tester.enterText(find.byType(TextField), 'seminar');
    await tester.pump();

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    final homeField = tester.widget<TextField>(find.byType(TextField));
    expect(homeField.controller?.text, 'seminar');
    expect(events.query, 'seminar');
  });

  testWidgets('hapus pencarian mengosongkan kedua field', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    await tester.runAsync(() => events.loadEvents());

    await tester.pumpWidget(_app(events: events, api: api));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'konser');
    await tester.pump();
    await tester.tap(find.text('Jelajahi'));
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    try {
      await tester.tap(find.bySemanticsLabel('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(events.query, isEmpty);
    } finally {
      semantics.dispose();
    }

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    final homeField = tester.widget<TextField>(find.byType(TextField));
    expect(homeField.controller?.text, isEmpty);
  });
}
