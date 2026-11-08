import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/favorite/favorite_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart';

/// Favorit adalah aksi langsung: melepas hati langsung menghilangkan kartu.
void main() {
  testWidgets('membatalkan favorit langsung menghilangkan kartu dari layar', (
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
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FavoriteScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(EventGridCard), findsNWidgets(2));

    // Lepas favorit pada kartu pertama.
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();

    // Kartu langsung hilang, bukan menunggu layar dibuka ulang.
    expect(find.byType(EventGridCard), findsOneWidget);
    expect(fav.isFav(events.events[0].id), isFalse);
    expect(fav.ids.length, 1);
  });

  testWidgets('favorit baru dari layar lain langsung tampil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    final fav = FavoriteProvider(api: api);
    await tester.runAsync(() async {
      await events.loadEvents();
      await fav.load();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: fav),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FavoriteScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(EventGridCard), findsNothing);

    await tester.runAsync(() => fav.toggle(events.events[2].id));
    await tester.pump();

    expect(find.byType(EventGridCard), findsOneWidget);
    expect(fav.ids, contains(events.events[2].id));
  });
}
