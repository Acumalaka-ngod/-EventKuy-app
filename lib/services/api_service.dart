import '../models/check_in_result.dart';
import '../models/checkout_result.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../models/voucher.dart';

/// Kontrak data layer EventKuy.
/// Implementasi produksi: [SupabaseApi]. Implementasi test: [MockApiService].
abstract class EventKuyApi {
  Future<List<Event>> fetchEvents();

  Future<List<Ticket>> fetchTickets();

  Future<List<Ticket>> fetchEventTickets(String eventId);

  /// Beli [qty] tiket sekaligus. Server memvalidasi stok dan memastikan
  /// satu voucher hanya bisa dipakai sekali oleh user yang sama.
  Future<CheckoutResult> checkout({
    required String eventId,
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
  });

  Future<CheckInResult> checkIn(String code);

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
}
