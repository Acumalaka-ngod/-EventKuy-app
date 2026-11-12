import 'dart:async';

import '../models/app_notification.dart';
import '../models/check_in_result.dart';
import '../models/checkout_result.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../models/organizer.dart';
import '../models/ticket.dart';
import '../models/transaction_record.dart';
import '../models/voucher.dart';
import 'api_service.dart';

/// Data layer palsu untuk widget test (tanpa jaringan/Supabase).
/// Aplikasi produksi memakai [SupabaseApi].
class MockApiService implements EventKuyApi {
  MockApiService({this.organizerId});

  /// ID organizer yang dipakai untuk event baru. Di produksi nilainya
  /// berasal dari sesi Supabase; di test diisi agar dashboard bisa
  /// memfilter event milik user.
  final String? organizerId;

  final Set<String> _favorites = {};
  final Set<String> _usedVouchers = {};
  final List<Ticket> _tickets = [];
  final List<TransactionRecord> _transactions = [];
  int _counter = 0;
  final StreamController<void> _ticketChanges =
      StreamController<void>.broadcast();

  void _notifyTicketChanged() {
    if (!_ticketChanges.isClosed) _ticketChanges.add(null);
  }

  int _soldOf(Event event) {
    final owned = _tickets
        .where(
          (t) =>
              t.eventId == event.id &&
              (t.status == 'paid' || t.status == 'checked_in'),
        )
        .length;
    return event.sold + owned;
  }

  @override
  Stream<void> watchTickets() => _ticketChanges.stream;

  // Kalau file aset lokal belum ada, EventImage otomatis fallback ke picsum.
  static String img(String asset, String seed) => asset;

  // Organizer demo — mirror seed di supabase/p2_event_content.sql.
  static final _organizerEventkuy = Organizer(
    id: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
    name: 'EventKuy Official',
    bio:
        'Penyelenggara resmi platform EventKuy. Menyelenggarakan berbagai acara musik, workshop, seminar, dan olahraga di seluruh Indonesia.',
    city: 'Jakarta',
    verified: true,
  );
  static final _organizerRagaNusantara = Organizer(
    id: 'b25d7744-cee0-4bf7-b123-dea60edd901b',
    name: 'Raga Nusantara',
    bio:
        'Komunitas penggemar musik lokal yang mengedepankan karya anak bangsa dari Sabang hingga Merauke.',
    city: 'Bandung',
    verified: true,
  );
  static final _organizerTechCamp = Organizer(
    id: 'c36e8855-dff1-4c08-c234-efb71fee022c',
    name: 'TechCamp Indonesia',
    bio:
        'Platform edukasi teknologi dan startup dengan workshop hands-on serta seminar dari praktisi industri.',
    city: 'Jakarta',
    verified: false,
  );

  final List<Event> _events = [
    Event(
      id: '11111111-1111-4111-8111-000000000001',
      organizerId: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
      organizer: _organizerEventkuy,
      title: 'Sound of Tomorrow',
      description:
          'Sound of Tomorrow adalah festival musik yang menghadirkan deretan musisi terbaik dari berbagai genre. Nikmati pengalaman tak terlupakan bersama teman-teman, dengan panggung megah dan fasilitas lengkap.',
      date: DateTime(2025, 7, 12),
      location: 'Istora Senayan, Jl. Pintu Satu Senayan No. 1, Jakarta Pusat',
      price: 750000,
      quota: 3000,
      rating: 4.9,
      ratingCount: 320,
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
      organizerId: 'b25d7744-cee0-4bf7-b123-dea60edd901b',
      organizer: _organizerRagaNusantara,
      title: 'We The Fest 2025',
      description: 'Festival musik tahunan terbesar di Jakarta.',
      date: DateTime(2025, 7, 25),
      location:
          'Gelora Bung Karno (GBK), Jl. Pintu Satu Senayan, Jakarta Pusat',
      price: 750000,
      quota: 10000,
      rating: 4.7,
      ratingCount: 180,
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
      organizerId: 'c36e8855-dff1-4c08-c234-efb71fee022c',
      organizer: _organizerTechCamp,
      title: 'Photography Workshop',
      description: 'Workshop fotografi untuk pemula sampai pro.',
      date: DateTime(2025, 7, 12),
      location: 'Braga Creative Hub, Jl. Braga No. 21, Bandung',
      price: 250000,
      quota: 200,
      rating: 4.5,
      ratingCount: 45,
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
      organizerId: 'c36e8855-dff1-4c08-c234-efb71fee022c',
      organizer: _organizerTechCamp,
      title: 'Future of Technology',
      description: 'Seminar AI, startup, dan masa depan teknologi.',
      date: DateTime(2025, 7, 18),
      location:
          'Jakarta Convention Center, Jl. Gatot Subroto, Jakarta Pusat',
      price: 150000,
      quota: 1000,
      rating: 4.3,
      ratingCount: 90,
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
      organizerId: 'b25d7744-cee0-4bf7-b123-dea60edd901b',
      organizer: _organizerRagaNusantara,
      title: 'Jakarta Running Festival',
      description: 'Lari bersama 5K & 10K di Monas.',
      date: DateTime(2025, 7, 27),
      location: 'Kawasan Monas, Jl. Silang Monas, Jakarta Pusat',
      price: 300000,
      quota: 5000,
      rating: 4.8,
      ratingCount: 210,
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
      organizerId: 'a14d6633-bdd9-4af6-a012-cda59d8cc9fa',
      organizer: _organizerEventkuy,
      title: 'UI/UX Design Workshop',
      description: 'Belajar desain produk dari praktisi.',
      date: DateTime(2025, 7, 5),
      location: 'GoWork Chubb Square, Jl. M.H. Thamrin No. 10, Jakarta Pusat',
      price: 200000,
      quota: 300,
      rating: 4.6,
      ratingCount: 60,
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
      organizerId: 'c36e8855-dff1-4c08-c234-efb71fee022c',
      organizer: _organizerTechCamp,
      title: 'Digital Marketing Summit',
      description: 'Strategi growth & ads terbaru.',
      date: DateTime(2025, 7, 8),
      location: 'Gedung Merdeka, Jl. Asia Afrika No. 65, Bandung',
      price: 350000,
      quota: 500,
      rating: 4.4,
      ratingCount: 75,
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
    return _events
        .map((event) => event.copyWith(sold: _soldOf(event)))
        .toList(growable: false);
  }

  @override
  Future<Event> createEvent(EventDraft draft) async {
    final event = Event(
      id: 'mock-event-${DateTime.now().microsecondsSinceEpoch}',
      organizerId: organizerId,
      title: draft.title.trim(),
      description: draft.description.trim(),
      date: DateTime(draft.date.year, draft.date.month, draft.date.day),
      location: draft.location.trim(),
      price: draft.price,
      quota: draft.quota,
      imageUrl: draft.imageUrl.trim(),
      imageUrls: List.unmodifiable(draft.imageUrls),
      category: draft.category.trim(),
      tags: List.unmodifiable(draft.tags),
      timeRange: draft.timeRange.trim(),
    );
    _events.add(event);
    _events.sort((a, b) => a.date.compareTo(b.date));
    return event;
  }

  @override
  Future<Event> updateEvent(String eventId, EventDraft draft) async {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index == -1) throw StateError('Event tidak ditemukan.');

    final old = _events[index];
    final updated = Event(
      id: old.id,
      organizerId: old.organizerId,
      organizerProfileId: old.organizerProfileId,
      organizer: old.organizer,
      title: draft.title.trim(),
      description: draft.description.trim(),
      date: DateTime(draft.date.year, draft.date.month, draft.date.day),
      location: draft.location.trim(),
      price: draft.price,
      quota: draft.quota,
      sold: old.sold,
      imageUrl: draft.imageUrl.trim(),
      imageUrls: List.unmodifiable(draft.imageUrls),
      category: draft.category.trim(),
      tags: List.unmodifiable(draft.tags),
      timeRange: draft.timeRange.trim(),
      rating: old.rating,
      ratingCount: old.ratingCount,
    );
    _events[index] = updated;
    _events.sort((a, b) => a.date.compareTo(b.date));
    return updated;
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
  Future<CheckoutResult> checkout({
    required String eventId,
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  }) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    if (qty < 1) {
      throw StateError('Jumlah tiket minimal 1.');
    }

    final sisa = event.available == null
        ? null
        : event.quota - _soldOf(event);
    if (sisa != null && sisa <= 0) {
      throw StateError('Stok tiket habis.');
    }
    if (sisa != null && qty > sisa) {
      throw StateError('Sisa tiket tinggal $sisa.');
    }

    var discount = 0;
    String? appliedVoucher;
    if (voucherCode != null && voucherCode.trim().isNotEmpty) {
      final voucher = await fetchVoucher(voucherCode);
      if (voucher == null) {
        throw StateError('Voucher tidak valid atau kedaluwarsa.');
      }
      if (_usedVouchers.contains(voucher.code)) {
        throw StateError('Voucher ${voucher.code} sudah pernah kamu pakai.');
      }
      appliedVoucher = voucher.code;
      discount = voucher.discount;
    }

    final subtotal = event.price * qty;
    final adminFee = 2500 * qty;
    final total = (subtotal + adminFee - discount).clamp(0, 1 << 31).toInt();

    final created = <Ticket>[];
    for (var i = 0; i < qty; i++) {
      _counter += 1;
      final ticket = Ticket(
        code: 'EVK-MOCK${_counter.toString().padLeft(6, '0')}',
        eventId: event.id,
        eventTitle: event.title,
        status: 'paid',
      );
      _tickets.insert(0, ticket);
      created.add(ticket);

      // Sama seperti RPC checkout: satu transaksi per tiket, diskon hanya
      // dibebankan pada tiket pertama.
      final ticketDiscount = i == 0 ? discount : 0;
      _transactions.insert(
        0,
        TransactionRecord(
          id: 'TRX-MOCK${_counter.toString().padLeft(6, '0')}',
          eventTitle: event.title,
          ticketCode: ticket.code,
          total: (event.price + 2500 - ticketDiscount).clamp(0, 1 << 31).toDouble(),
          paymentMethod: paymentMethod,
          status: 'paid',
          createdAt: DateTime.now(),
          buyerName: buyerName.trim(),
          buyerEmail: buyerEmail.trim(),
          buyerPhone: buyerPhone.trim(),
        ),
      );
    }

    if (appliedVoucher != null) _usedVouchers.add(appliedVoucher);
    _notifyTicketChanged();

    return CheckoutResult(
      tickets: List.unmodifiable(created),
      subtotal: subtotal,
      adminFee: adminFee,
      discount: discount,
      total: total,
    );
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
  Future<List<TransactionRecord>> fetchTransactions() async {
    return List.unmodifiable(_transactions);
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

  @override
  Future<Set<String>> fetchUsedVoucherCodes() async => Set.of(_usedVouchers);

  // ── Notifikasi mock (P2 scaffold) ─────────────────────────────────

  final List<AppNotification> _notifications = [];
  final Set<String> _deviceTokens = {};

  @override
  Future<List<AppNotification>> fetchNotifications() async =>
      List.unmodifiable(_notifications);

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final i = _notifications.indexWhere((n) => n.id == notificationId);
    if (i == -1) return;
    final n = _notifications[i];
    if (!n.isRead) {
      _notifications[i] = AppNotification(
        id: n.id,
        userId: n.userId,
        title: n.title,
        body: n.body,
        eventId: n.eventId,
        isRead: true,
        readAt: DateTime.now(),
        createdAt: n.createdAt,
      );
    }
  }

  @override
  Future<List<String>> fetchDeviceTokens() async =>
      List.unmodifiable(_deviceTokens);

  @override
  Future<void> registerDeviceToken({
    required String token,
    String platform = 'unknown',
  }) async {
    _deviceTokens.add(token);
  }

  /// Seed notifikasi demo untuk pengujian UI.
  void seedNotification({
    required String id,
    required String userId,
    required String title,
    required String body,
    String? eventId,
    bool isRead = false,
  }) {
    _notifications.add(
      AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        eventId: eventId,
        isRead: isRead,
        readAt: isRead ? DateTime.now() : null,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Network fallback saat file aset lokal belum disediakan.
  static String fallbackUrl(String seed) =>
      'https://picsum.photos/seed/eventkuy$seed/600/400';
}
