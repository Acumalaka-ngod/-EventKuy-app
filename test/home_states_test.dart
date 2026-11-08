import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/explore/explore_screen.dart';
import 'package:eventkuy/screens/home/home_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

class _FailingApi extends MockApiService {
  @override
  Future<List<Event>> fetchEvents() async {
    throw StateError('Jaringan bermasalah.');
  }
}

Widget _app({required EventProvider events, required MockApiService api}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider<EventProvider>.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
  );
}

Widget _exploreApp({
  required EventProvider events,
  required MockApiService api,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EventProvider>.value(value: events),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const ExploreScreen()),
  );
}

void main() {
  group('Beranda', () {
    testWidgets('load gagal menampilkan error + Coba Lagi, bukan empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = _FailingApi();
      final events = EventProvider(api: api);

      await tester.pumpWidget(_app(events: events, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Event'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Event Tidak Ditemukan'), findsNothing);
    });

    testWidgets('hasil pencarian kosong menampilkan empty state', (
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

      await tester.enterText(find.byType(TextField), 'zzzz-tidak-ada');
      await tester.pumpAndSettle();

      expect(find.text('Event Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Gagal Memuat Event'), findsNothing);
    });
  });

  group('Jelajahi', () {
    testWidgets('load gagal menampilkan error + Coba Lagi, bukan empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final api = _FailingApi();
      final events = EventProvider(api: api);

      await tester.pumpWidget(_exploreApp(events: events, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Event'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Event Tidak Ditemukan'), findsNothing);
    });
  });
}
