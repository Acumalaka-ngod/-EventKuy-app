import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/event_draft.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/services/mock_api_service.dart';

EventDraft _draft({String title = 'Konser Kampus'}) {
  return EventDraft(
    title: title,
    description: 'Konser musik mahasiswa dengan bintang tamu lokal.',
    date: DateTime(2026, 11, 20),
    location: 'Auditorium Kampus, Bandung',
    price: 75000,
    quota: 500,
    category: 'Konser',
    timeRange: '18:00 - 22:00',
  );
}

void main() {
  group('EventDraft', () {
    test('toJson mengirim tanggal tanpa komponen waktu', () {
      final json = _draft().toJson();

      expect(json['date'], '2026-11-20');
      expect(json['title'], 'Konser Kampus');
      expect(json['location'], 'Auditorium Kampus, Bandung');
      expect(json['price'], 75000);
      expect(json['quota'], 500);
      expect(json['time_range'], '18:00 - 22:00');
    });

    test('fromEvent menyalin seluruh kolom yang bisa diedit', () {
      final draft = _draft();
      final event = EventDraftTestHelper.eventFromDraft(draft);
      final copy = EventDraft.fromEvent(event);

      expect(copy.title, draft.title);
      expect(copy.description, draft.description);
      expect(copy.date, draft.date);
      expect(copy.location, draft.location);
      expect(copy.price, draft.price);
      expect(copy.quota, draft.quota);
      expect(copy.category, draft.category);
      expect(copy.timeRange, draft.timeRange);
    });
  });

  group('MockApiService event CRU', () {
    test('createEvent menyimpan event dengan organizer yang benar', () async {
      final api = MockApiService(organizerId: 'org-1');
      final created = await api.createEvent(_draft());

      expect(created.organizerId, 'org-1');
      expect(created.title, 'Konser Kampus');
      expect(created.price, 75000);

      final events = await api.fetchEvents();
      expect(events.any((event) => event.id == created.id), isTrue);
    });

    test('updateEvent mengubah kolom dan mempertahankan tiket terjual', () async {
      final api = MockApiService();
      final before = (await api.fetchEvents()).first;
      final updated = await api.updateEvent(
        before.id,
        _draft(title: 'Judul Baru'),
      );

      expect(updated.id, before.id);
      expect(updated.title, 'Judul Baru');
      expect(updated.sold, before.sold);
      expect(updated.rating, before.rating);
    });

    test('updateEvent melempar error bila event tidak ditemukan', () async {
      final api = MockApiService();

      await expectLater(
        api.updateEvent('tidak-ada', _draft()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('EventProvider.saveEvent', () {
    test('event baru langsung masuk daftar lokal', () async {
      final api = MockApiService(organizerId: 'org-1');
      final provider = EventProvider(api: api);
      await provider.loadEvents();
      final before = provider.events.length;

      final created = await provider.saveEvent(draft: _draft());

      expect(provider.events.length, before + 1);
      expect(provider.eventById(created.id)?.title, 'Konser Kampus');
      expect(provider.events.last.id, created.id);
    });

    test('perubahan event langsung terlihat dan sold tidak berubah', () async {
      final api = MockApiService();
      final provider = EventProvider(api: api);
      await provider.loadEvents();
      final target = provider.events.first;
      final sold = target.sold;

      await provider.saveEvent(
        eventId: target.id,
        draft: _draft(title: 'Judul Hasil Edit'),
      );

      final updated = provider.eventById(target.id)!;
      expect(updated.title, 'Judul Hasil Edit');
      expect(updated.sold, sold);
      expect(updated.description, contains('Konser musik'));
    });
  });
}

/// Helper kecil agar test EventDraft tidak bergantung pada constructor Event
/// yang panjang.
class EventDraftTestHelper {
  static Event eventFromDraft(EventDraft draft) {
    return Event(
      id: 'evt-1',
      title: draft.title,
      description: draft.description,
      date: draft.date,
      location: draft.location,
      price: draft.price,
      quota: draft.quota,
      imageUrl: draft.imageUrl,
      imageUrls: draft.imageUrls,
      category: draft.category,
      tags: draft.tags,
      timeRange: draft.timeRange,
    );
  }
}
