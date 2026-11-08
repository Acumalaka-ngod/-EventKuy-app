import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/services/share_service.dart';

Event _event() => Event(
  id: 'evt-1',
  title: 'Konser Senja',
  description: 'Konser musik senja yang penuh energi.',
  date: DateTime(2026, 11, 8, 19),
  location: 'Istora Senayan, Jakarta',
  price: 150000,
  quota: 100,
  imageUrl: '',
  category: 'Konser',
  timeRange: '19:00 - 22:00',
);

Widget _app(Event event) {
  return ChangeNotifierProvider(
    create: (_) => FavoriteProvider(api: MockApiService()),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: EventDetailScreen(event: event),
    ),
  );
}

void main() {
  group('ShareService.shareText', () {
    test('hasil berisi judul, tanggal, lokasi, harga, dan tautan deep link', () {
      final event = _event();
      final text = ShareService.shareText(event);

      expect(text, contains(event.title));
      expect(text, contains('8 November 2026'));
      expect(text, contains('19:00 - 22:00 WIB'));
      expect(text, contains(event.location));
      expect(text, contains('Rp 150.000'));
      expect(text, contains('eventkuy://event/evt-1'));
      expect(text, contains('EventKuy'));
    });
  });

  group('ShareService.share', () {
    test('fallback ke clipboard saat share sheet tidak tersedia', () async {
      // Di lingkungan test, SharePlus gagal/unavailable -> fallback clipboard.
      final result = await ShareService.share('Teks share uji coba');
      expect(result, ShareResult.copied);
    });
  });

  group('EventDetailScreen tombol bagikan', () {
    testWidgets('tombol share tersedia', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event();
      await tester.pumpWidget(_app(event));
      await tester.pump();

      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
