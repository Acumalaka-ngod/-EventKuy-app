import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/organizer.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/event/event_detail_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

Organizer _organizer() => const Organizer(
  id: 'org-1',
  name: 'Penyelenggara Demo',
  bio: 'Ini adalah bio penyelenggara demo.',
  city: 'Jakarta',
  verified: true,
);

Event _event({Organizer? organizer, double rating = 0, int ratingCount = 0}) =>
    Event(
      id: 'evt-1',
      organizerId: 'org-1',
      organizer: organizer,
      title: 'Konser Senja',
      description: 'Konser musik senja yang penuh energi.',
      date: DateTime(2026, 11, 8, 19),
      location: 'Istora Senayan, Jakarta',
      price: 150000,
      quota: 100,
      rating: rating,
      ratingCount: ratingCount,
      imageUrl: '',
      category: 'Konser',
      timeRange: '19:00 - 22:00',
    );

Widget _app(Event event) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => EventProvider(api: MockApiService()),
      ),
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
  group('Organizer model', () {
    test('parsing dari JSON', () {
      final org = Organizer.fromJson({
        'id': 'org-1',
        'name': 'Penyelenggara Demo',
        'bio': 'Bio demo.',
        'city': 'Jakarta',
        'verified': true,
      });
      expect(org.id, 'org-1');
      expect(org.name, 'Penyelenggara Demo');
      expect(org.bio, 'Bio demo.');
      expect(org.city, 'Jakarta');
      expect(org.verified, isTrue);
      expect(org.initial, 'P');
    });

    test('initial dari nama kosong', () {
      final org = const Organizer(
        id: 'org-1',
        name: '',
        bio: '',
        city: '',
        verified: false,
      );
      expect(org.initial, '?');
    });
  });

  group('Event model', () {
    test('copyWith mempertahankan organizer dan rating', () {
      final event = _event(
        organizer: _organizer(),
        rating: 4.5,
        ratingCount: 10,
      );
      final updated = event.copyWith(sold: 5);
      expect(updated.sold, 5);
      expect(updated.organizer?.name, 'Penyelenggara Demo');
      expect(updated.rating, 4.5);
      expect(updated.ratingCount, 10);
    });

    test('fromJson parsing organizer nested', () {
      final event = Event.fromJson({
        'id': 'evt-1',
        'title': 'Test',
        'date': '2026-11-08',
        'location': 'Jakarta',
        'price': 100000,
        'quota': 100,
        'category': 'Konser',
        'organizers': {
          'id': 'org-1',
          'name': 'Organizer Test',
          'city': 'Bandung',
          'verified': false,
        },
        'rating': 4.2,
        'rating_count': 25,
      });
      expect(event.organizer?.name, 'Organizer Test');
      expect(event.organizer?.city, 'Bandung');
      expect(event.organizer?.verified, isFalse);
      expect(event.rating, 4.2);
      expect(event.ratingCount, 25);
    });
  });

  group('EventDetailScreen menampilkan data nyata', () {
    testWidgets('tampilkan rating dan organizer dari model, bukan statis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event(
        organizer: _organizer(),
        rating: 4.5,
        ratingCount: 120,
      );
      await tester.pumpWidget(_app(event));
      await tester.pump();

      // Rating dan jumlah ulasan dari model
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(120 ulasan)'), findsOneWidget);

      // Nama organizer dan bio dari model
      expect(find.text('Penyelenggara Demo'), findsOneWidget);
      expect(find.text('Ini adalah bio penyelenggara demo.'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);

      // Tidak ada teks statis lama
      expect(find.text('4.9'), findsNothing);
      expect(find.text('(320 ulasan)'), findsNothing);
      expect(find.text('EventKuy Official'), findsNothing);
      expect(find.text('Ikuti'), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fallback "Belum ada ulasan" bila rating_count 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event(rating: 0, ratingCount: 0);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      expect(find.text('Belum ada ulasan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fallback organizer "EventKuy Official" bila null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final event = _event(organizer: null);
      await tester.pumpWidget(_app(event));
      await tester.pump();

      expect(find.text('EventKuy Official'), findsOneWidget);
      expect(find.text('Penyelenggara Demo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('MockApiService', () {
    test('fetchEvents mengembalikan organizer dan rating', () async {
      final api = MockApiService();
      final events = await api.fetchEvents();
      expect(events, isNotEmpty);

      final first = events.first;
      expect(first.organizer, isNotNull);
      expect(first.organizer?.name, isNotEmpty);
      expect(first.rating, greaterThan(0));
      expect(first.ratingCount, greaterThan(0));
    });
  });
}
