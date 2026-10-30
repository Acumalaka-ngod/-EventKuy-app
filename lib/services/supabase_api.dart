import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../models/check_in_result.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../models/voucher.dart';
import 'api_service.dart';

/// Implementasi data layer memakai Supabase (PostgREST + RPC).
class SupabaseApi implements EventKuyApi {
  SupabaseClient get _client {
    if (!AppConfig.hasSupabaseConfig) {
      throw StateError(
        'Supabase belum dikonfigurasi. Jalankan aplikasi dengan '
        '--dart-define=SUPABASE_URL dan --dart-define=SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }
    return id;
  }

  @override
  Future<List<Event>> fetchEvents() async {
    final rows = await _client
        .from('events')
        .select()
        .order('date', ascending: true);
    return rows
        .map((row) => Event.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<List<Ticket>> fetchTickets() async {
    final rows = await _client
        .from('tickets')
        .select('code, event_id, status, events(title)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(_ticketFromRow).toList(growable: false);
  }

  @override
  Future<List<Ticket>> fetchEventTickets(String eventId) async {
    final rows = await _client
        .from('tickets')
        .select('code, event_id, status, events(title)')
        .eq('event_id', eventId)
        .order('created_at', ascending: true);
    return rows.map(_ticketFromRow).toList(growable: false);
  }

  Ticket _ticketFromRow(Map<String, dynamic> row) {
    final event = row['events'];
    final title = event is Map ? event['title'] as String? : null;
    return Ticket.fromJson({
      'code': row['code'],
      'event_id': row['event_id'],
      'event_title': title ?? '',
      'status': row['status'],
    });
  }

  @override
  Future<Ticket> checkout({
    required String eventId,
    String? voucherCode,
    String paymentMethod = 'GoPay',
  }) async {
    final result = await _client.rpc('checkout', params: {
      'p_event_id': eventId,
      'p_voucher_code': voucherCode,
      'p_payment_method': paymentMethod,
    });

    final data = Map<String, dynamic>.from(result as Map);
    return Ticket(
      code: data['ticket_code'] as String,
      eventId: data['event_id'].toString(),
      eventTitle: data['event_title'] as String? ?? '',
      status: data['status'] as String? ?? 'paid',
    );
  }

  @override
  Future<CheckInResult> checkIn(String code) async {
    final result = await _client.rpc(
      'check_in_ticket',
      params: {'p_code': code},
    );
    final data = Map<String, dynamic>.from(result as Map);
    return CheckInResult(
      code: data['code'] as String? ?? code,
      eventTitle: data['event_title'] as String? ?? '',
    );
  }

  /// Pantau perubahan tiket user lewat Supabase Realtime.
  /// Stream hanya dipakai sebagai pemicu; data lengkap tetap diambil
  /// lewat [fetchTickets] supaya judul event ikut terbawa.
  @override
  Stream<void> watchTickets() {
    if (!AppConfig.hasSupabaseConfig) return const Stream<void>.empty();
    final id = _client.auth.currentUser?.id;
    if (id == null) return const Stream<void>.empty();
    return _client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('user_id', id)
        .map((_) {});
  }

  @override
  Future<Set<String>> fetchFavoriteIds() async {
    final rows = await _client
        .from('favorites')
        .select('event_id')
        .eq('user_id', _userId);
    return rows
        .map((row) => row['event_id'].toString())
        .toSet();
  }

  @override
  Future<void> addFavorite(String eventId) async {
    await _client.from('favorites').insert({
      'user_id': _userId,
      'event_id': eventId,
    });
  }

  @override
  Future<void> removeFavorite(String eventId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('event_id', eventId);
  }

  @override
  Future<Voucher?> fetchVoucher(String code) async {
    final row = await _client
        .from('vouchers')
        .select('code, discount')
        .eq('code', code.trim().toUpperCase())
        .maybeSingle();
    if (row == null) return null;
    return Voucher.fromJson(Map<String, dynamic>.from(row));
  }
}
