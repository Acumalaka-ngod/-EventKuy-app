import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/widgets/event_gallery.dart';

Event _event({
  String imageUrl = 'assets/images/event_sound.jpg',
  List<String> extra = const [],
}) {
  return Event(
    id: '11111111-1111-4111-8111-000000000001',
    title: 'Sound of Tomorrow',
    description: 'Festival musik terbesar tahun ini.',
    date: DateTime(2025, 7, 12),
    location: 'Istora Senayan, Jakarta',
    price: 750000,
    quota: 3000,
    imageUrl: imageUrl,
    imageUrls: extra,
    category: 'Konser',
    tags: const ['Musik', 'Festival'],
    timeRange: '15:00 - 23:00',
  );
}

void main() {
  group('Event.galleryImages', () {
    test('menggabungkan gambar utama dengan galeri', () {
      final event = _event(
        extra: const ['assets/images/event_wtf.jpg'],
      );

      expect(event.galleryImages, [
        'assets/images/event_sound.jpg',
        'assets/images/event_wtf.jpg',
      ]);
    });

    test('menghapus duplikat dan entri kosong', () {
      final event = _event(
        extra: const [
          '',
          'assets/images/event_sound.jpg',
          '  ',
          'assets/images/event_tech.jpg',
        ],
      );

      expect(event.galleryImages, [
        'assets/images/event_sound.jpg',
        'assets/images/event_tech.jpg',
      ]);
    });

    test('tetap berisi satu gambar walau galeri kosong', () {
      expect(_event().galleryImages, ['assets/images/event_sound.jpg']);
    });
  });

  group('EventGallery', () {
    testWidgets('menampilkan counter dan bisa di-swipe ke foto berikutnya', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 390,
              child: EventGallery(
                eventId: '11111111-1111-4111-8111-000000000001',
                images: const [
                  'assets/images/event_sound.jpg',
                  'assets/images/event_wtf.jpg',
                  'assets/images/event_tech.jpg',
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 / 3'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-380, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('counter dan indikator disembunyikan untuk satu foto', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 390,
              child: EventGallery(
                eventId: '11111111-1111-4111-8111-000000000001',
                images: const ['assets/images/event_sound.jpg'],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining(' / '), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
