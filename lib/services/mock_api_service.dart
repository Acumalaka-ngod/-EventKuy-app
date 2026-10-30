import 'dart:async';

import '../models/check_in_result.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../models/voucher.dart';
import 'api_service.dart';

/// Data layer palsu untuk widget test (tanpa jaringan/Supabase).
/// Aplikasi produksi memakai [SupabaseApi].
class MockApiService implements EventKuyApi {
  final Set<String> _favorites = {};
  final List<Ticket> _tickets = [];
  int _counter = 0;
  final StreamController<void> _ticketChanges =
      StreamController<void>.broadcast();

  void _notifyTicketChanged() {
    if (!_ticketChanges.isClosed) _ticketChanges.add(null);
  }

  @override
  Stream<void> watchTickets() => _ticketChanges.stream;

  // Kalau file aset lokal belum ada, EventImage otomatis fallback ke picsum.
  static String img(String asset, String seed) => asset;

  final List<Event> _events = [
    Event(
      id: '11111111-1111-4111-8111-000000000001',
      organizerId: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
      title: 'Sound of Tomorrow',
      description:
          'Sound of Tomorrow adalah festival musik yang menghadirkan deretan musisi terbaik dari berbagai genre. Nikmati pengalaman tak terlupakan bersama teman-teman, dengan panggung megah dan fasilitas lengkap.',
      date: DateTime(2025, 7, 12),
      location: 'Istora Senayan, Jl. Pintu Satu Senayan No. 1, Jakarta Pusat',
      price: 750000,
      quota: 3000,
      imageUrl: img('assets/images/event_sound.jpg', 'concert'),
      imageUrls: const [
        'assets/images/event_wtf.jpg',
        'assets/images/event_photo.jpg',
      ],
      category: 'Konser',
      tags: const ['Musik', 'Festival', 'Food & Beverage'],
      timeRange: '15:00 - 23:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000002',
      title: 'We The Fest 2025',
      description: 'Festival musik tahunan terbesar di Jakarta.',
      date: DateTime(2025, 7, 25),
      location:
          'Gelora Bung Karno (GBK), Jl. Pintu Satu Senayan, Jakarta Pusat',
      price: 750000,
      quota: 10000,
      imageUrl: img('assets/images/event_wtf.jpg', 'festival'),
      imageUrls: const [
        'assets/images/event_sound.jpg',
        'assets/images/event_marketing.jpg',
      ],
      category: 'Konser',
      tags: const ['Musik', 'Festival'],
      timeRange: '14:00 - 23:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000003',
      title: 'Photography Workshop',
      description: 'Workshop fotografi untuk pemula sampai pro.',
      date: DateTime(2025, 7, 12),
      location: 'Braga Creative Hub, Jl. Braga No. 21, Bandung',
      price: 250000,
      quota: 200,
      imageUrl: img('assets/images/event_photo.jpg', 'workshop'),
      imageUrls: const [
        'assets/images/event_uiux.jpg',
        'assets/images/event_sound.jpg',
      ],
      category: 'Workshop',
      tags: const ['Fotografi'],
      timeRange: '09:00 - 15:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000004',
      title: 'Future of Technology',
      description: 'Seminar AI, startup, dan masa depan teknologi.',
      date: DateTime(2025, 7, 18),
      location:
          'Jakarta Convention Center, Jl. Gatot Subroto, Jakarta Pusat',
      price: 150000,
      quota: 1000,
      imageUrl: img('assets/images/event_tech.jpg', 'seminar'),
      imageUrls: const [
        'assets/images/event_marketing.jpg',
        'assets/images/event_uiux.jpg',
      ],
      category: 'Seminar',
      tags: const ['Teknologi'],
      timeRange: '09:00 - 17:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000005',
      title: 'Jakarta Running Festival',
      description: 'Lari bersama 5K & 10K di Monas.',
      date: DateTime(2025, 7, 27),
      location: 'Kawasan Monas, Jl. Silang Monas, Jakarta Pusat',
      price: 300000,
      quota: 5000,
      imageUrl: img('assets/images/event_run.jpg', 'running'),
      imageUrls: const [
        'assets/images/event_sound.jpg',
        'assets/images/event_wtf.jpg',
      ],
      category: 'Olahraga',
      tags: const ['Lari', 'Komunitas'],
      timeRange: '05:00 - 10:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000006',
      title: 'UI/UX Design Workshop',
      description: 'Belajar desain produk dari praktisi.',
      date: DateTime(2025, 7, 5),
      location: 'GoWork Chubb Square, Jl. M.H. Thamrin No. 10, Jakarta Pusat',
      price: 200000,
      quota: 300,
      imageUrl: img('assets/images/event_uiux.jpg', 'uiux'),
      imageUrls: const [
        'assets/images/event_photo.jpg',
        'assets/images/event_tech.jpg',
      ],
      category: 'Workshop',
      tags: const ['Desain'],
      timeRange: '10:00 - 16:00',
    ),
    Event(
      id: '11111111-1111-4111-8111-000000000007',
      title: 'Digital Marketing Summit',
      description: 'Strategi growth & ads terbaru.',
      date: DateTime(2025, 7, 8),
      location: 'Gedung Merdeka, Jl. Asia Afrika No. 65, Bandung',
      price: 350000,
      quota: 500,
      imageUrl: img('assets/images/event_marketing.jpg', 'marketing'),
      imageUrls: const [
        'assets/images/event_tech.jpg',
        'assets/images/event_wtf.jpg',
      ],
      category: 'Seminar',
      tags: const ['Bisnis'],
      timeRange: '09:00 - 17:00',
    ),
  ];

  @override
  Future<List<Event>> fetchEvents() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_events);
  }

  @override
  Future<List<Ticket>> fetchTickets() async {
    return List.unmodifiable(_tickets);
  }

  @override
  Future<List<Ticket>> fetchEventTickets(String eventId) async {
    return _tickets.where((t) => t.eventId == eventId).toList();
  }

  @override
  Future<Ticket> checkout({
    required String eventId,
    String? voucherCode,
    String paymentMethod = 'GoPay',
  }) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    _counter += 1;
    final ticket = Ticket(
      code: 'EVK-MOCK${_counter.toString().padLeft(6, '0')}',
      eventId: event.id,
      eventTitle: event.title,
      status: 'paid',
    );
    _tickets.insert(0, ticket);
    _notifyTicketChanged();
    return ticket;
  }

  @override
  Future<CheckInResult> checkIn(String code) async {
    final i = _tickets.indexWhere(
      (t) => t.code.toUpperCase() == code.trim().toUpperCase(),
    );
    if (i == -1) {
      throw StateError('Tiket tidak ditemukan');
    }
    if (_tickets[i].status == 'checked_in') {
      throw StateError('Tiket sudah pernah check-in');
    }
    _tickets[i] = _tickets[i].copyWith(status: 'checked_in');
    _notifyTicketChanged();

    var eventTitle = _tickets[i].eventTitle;
    if (eventTitle.isEmpty) {
      for (final event in _events) {
        if (event.id == _tickets[i].eventId) {
          eventTitle = event.title;
          break;
        }
      }
    }
    return CheckInResult(code: _tickets[i].code, eventTitle: eventTitle);
  }

  @override
  Future<Set<String>> fetchFavoriteIds() async => Set.of(_favorites);

  @override
  Future<void> addFavorite(String eventId) async {
    _favorites.add(eventId);
  }

  @override
  Future<void> removeFavorite(String eventId) async {
    _favorites.remove(eventId);
  }

  @override
  Future<Voucher?> fetchVoucher(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'EVENTKUY' || normalized == 'DISKON10') {
      return Voucher(code: normalized, discount: 25000);
    }
    return null;
  }

  /// Network fallback saat file aset lokal belum disediakan.
  static String fallbackUrl(String seed) =>
      'https://picsum.photos/seed/eventkuy$seed/600/400';
}
