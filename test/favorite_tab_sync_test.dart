import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/main_navigation.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart';

/// Regresi: melepas favorit tidak boleh langsung menghilangkan kartu dari
/// layar Favorit. Kartu baru disaring saat tab Favorit dibuka kembali.
void main() {
  testWidgets('melepas favorit tetap tampil sampai tab Favorit dibuka ulang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = MockApiService();
    final events = EventProvider(api: api);
    final favorites = FavoriteProvider(api: api);
    final tickets = TicketProvider(api: api, pollInterval: null);

    await tester.runAsync(() async {
      await events.loadEvents();
      await favorites.load();
      await favorites.toggle(events.events[0].id);
      await favorites.toggle(events.events[1].id);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: tickets),
          ChangeNotifierProvider.value(value: favorites),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MainNavigation(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Masuk tab Favorit: dua kartu tampil.
    await tester.tap(find.text('Favorit'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EventGridCard), findsNWidgets(2));

    // Lepas favorit kartu pertama: kartu tetap ada, hati jadi outline.
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();
    expect(find.byType(EventGridCard), findsNWidgets(2));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(favorites.isFav(events.events[0].id), isFalse);
    expect(favorites.ids.length, 1);

    // Pindah tab lalu kembali: shelf disaring, tinggal satu kartu.
    await tester.tap(find.text('Beranda'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Favorit'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(favorites.ids.length, 1);
    expect(favorites.shelfIds.length, 1);
    expect(find.byType(EventGridCard), findsOneWidget);
  });
}
