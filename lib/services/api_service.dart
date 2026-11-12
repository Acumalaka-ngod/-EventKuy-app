import '../models/app_notification.dart';
import '../models/check_in_result.dart';
import '../models/checkout_result.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../models/ticket.dart';
import '../models/transaction_record.dart';
import '../models/voucher.dart';

/// Kontrak data layer EventKuy.
/// Implementasi produksi: [SupabaseApi]. Implementasi test: [MockApiService].
abstract class EventKuyApi {
  Future<List<Event>> fetchEvents();

  /// Buat event baru milik organizer yang sedang login.
  Future<Event> createEvent(EventDraft draft);

  /// Ubah event milik organizer yang sedang login.
  Future<Event> updateEvent(String eventId, EventDraft draft);

  Future<List<Ticket>> fetchTickets();

  Future<List<Ticket>> fetchEventTickets(String eventId);

  /// Beli [qty] tiket sekaligus. Server memvalidasi stok dan memastikan
  /// satu voucher hanya bisa dipakai sekali oleh user yang sama.
  /// Data pembeli (nama, email, HP) disimpan pada setiap transaksi.
  Future<CheckoutResult> checkout({
    required String eventId,
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  });

  Future<CheckInResult> checkIn(String code);

  /// Riwayat transaksi milik user, terbaru dulu.
  Future<List<TransactionRecord>> fetchTransactions();

  /// Sinyal bahwa tiket milik user berubah (mis. organizer baru saja
  /// melakukan check-in). Implementasi produksi memakai Supabase Realtime;
  /// implementasi test memancarkan sinyal dari aksi mock.
  Stream<void> watchTickets();

  Future<Set<String>> fetchFavoriteIds();

  Future<void> addFavorite(String eventId);

  Future<void> removeFavorite(String eventId);

  Future<Voucher?> fetchVoucher(String code);

  /// Kode voucher yang sudah pernah dipakai user ini (sekali pakai per user).
  Future<Set<String>> fetchUsedVoucherCodes();

  // ── Notifikasi (P2 scaffold, tanpa Firebase) ──────────────────────

  /// Daftar notifikasi in-app milik user, terbaru dulu.
  Future<List<AppNotification>> fetchNotifications();

  /// Tandai notifikasi sebagai sudah dibaca.
  Future<void> markNotificationRead(String notificationId);

  /// Daftar token perangkat milik user (untuk push di masa depan).
  Future<List<String>> fetchDeviceTokens();

  /// Simpan token perangkat user (untuk push di masa depan).
  Future<void> registerDeviceToken({
    required String token,
    String platform = 'unknown',
  });
}
