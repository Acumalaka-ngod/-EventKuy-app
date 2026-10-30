import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/favorite/favorite_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart';

/// Favorit tidak langsung hilang saat tombol hati ditekan (anti salah pencet).
void main() {
  testWidgets('membatalkan favorit tidak menghilangkan kartu dari layar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    final fav = FavoriteProvider(api: api);
    await tester.runAsync(() async {
      await events.loadEvents();
      await fav.load();
      await fav.toggle(events.events[0].id);
      await fav.toggle(events.events[1].id);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: fav),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const FavoriteScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(EventGridCard), findsNWidgets(2));

    // Lepas favorit pada kartu pertama.
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();

    // Kartu tetap ada, hanya hatinya yang memutih (outline).
    expect(find.byType(EventGridCard), findsNWidgets(2));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(fav.isFav(events.events[0].id), isFalse);
  });

  testWidgets('memilih ulang hati mengembalikan status favorit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    final fav = FavoriteProvider(api: api);
    await tester.runAsync(() async {
      await events.loadEvents();
      await fav.load();
      await fav.toggle(events.events[0].id);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: fav),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const FavoriteScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byType(EventGridCard), findsOneWidget);
  });

  test('shelf favorit disaring ulang saat layar dibuka kembali', () async {
    final api = MockApiService();
    final fav = FavoriteProvider(api: api);
    final events = await api.fetchEvents();

    await fav.toggle(events[0].id);
    await fav.toggle(events[1].id);
    expect(fav.shelfIds.length, 2);

    await fav.toggle(events[0].id);
    // Belum disaring: kartu masih ditampilkan.
    expect(fav.shelfIds.length, 2);
    expect(fav.ids.length, 1);

    fav.syncShelf();
    expect(fav.shelfIds.length, 1);
    expect(fav.shelfIds, contains(events[1].id));
  });

  test('favorit baru dari layar lain langsung masuk shelf', () async {
    final api = MockApiService();
    final fav = FavoriteProvider(api: api);
    final events = await api.fetchEvents();

    fav.syncShelf();
    expect(fav.shelfIds, isEmpty);

    await fav.toggle(events[2].id);
    expect(fav.shelfIds, contains(events[2].id));
  });
}
