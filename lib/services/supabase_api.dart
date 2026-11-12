import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../models/app_notification.dart';
import '../models/check_in_result.dart';
import '../models/checkout_result.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../models/ticket.dart';
import '../models/transaction_record.dart';
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
        .select('*, organizers(name, bio, city, verified, avatar_url)')
        .order('date', ascending: true);

    // Jumlah tiket terjual per event (view `event_stock`).
    // Kalau view belum dibuat di database lama, anggap belum ada penjualan.
    final soldByEvent = <String, int>{};
    try {
      final stock = await _client.from('event_stock').select('event_id, sold');
      for (final row in stock) {
        soldByEvent[row['event_id'].toString()] =
            (row['sold'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      // Abaikan: stok ditampilkan sebagai "tersedia penuh".
    }

    return rows.map((row) {
      final json = Map<String, dynamic>.from(row);
      json['sold'] = soldByEvent[json['id'].toString()] ?? 0;
      // organizers dikembalikan sebagai list oleh PostgREST nested select;
      // ambil entri pertama bila ada.
      final orgList = json['organizers'];
      if (orgList is List && orgList.isNotEmpty) {
        json['organizer'] = orgList.first;
      }
      return Event.fromJson(json);
    }).toList(growable: false);
  }

  static const _eventSelect =
      '*, organizers(name, bio, city, verified, avatar_url)';

  @override
  Future<Event> createEvent(EventDraft draft) async {
    final organizerProfileId = await _ensureOrganizerProfile();
    final row = await _client
        .from('events')
        .insert({
          ...draft.toJson(),
          'organizer_id': _userId,
          'organizer_profile_id': organizerProfileId,
        })
        .select(_eventSelect)
        .single();

    return _eventFromRow(row);
  }

  @override
  Future<Event> updateEvent(String eventId, EventDraft draft) async {
    final row = await _client
        .from('events')
        .update(draft.toJson())
        .eq('id', eventId)
        .select(_eventSelect)
        .single();

    return _eventFromRow(row);
  }

  Event _eventFromRow(Map<String, dynamic> row) {
    final json = Map<String, dynamic>.from(row);
    final orgList = json['organizers'];
    if (orgList is List && orgList.isNotEmpty) {
      json['organizer'] = orgList.first;
    }
    return Event.fromJson(json);
  }

  /// Pastikan organizer punya baris `organizers` agar nama penyelenggara
  /// tampil di halaman detail event. Kegagalan di sini tidak menghalangi
  /// pembuatan event; `organizer_profile_id` boleh kosong.
  Future<String?> _ensureOrganizerProfile() async {
    try {
      final existing = await _client
          .from('organizers')
          .select('id')
          .eq('owner_id', _userId)
          .limit(1)
          .maybeSingle();
      if (existing != null) return existing['id'] as String?;

      final profile = await _client
          .from('profiles')
          .select('name')
          .eq('id', _userId)
          .maybeSingle();
      final name = (profile?['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;

      final inserted = await _client
          .from('organizers')
          .insert({'owner_id': _userId, 'name': name})
          .select('id')
          .single();
      return inserted['id'] as String?;
    } catch (_) {
      return null;
    }
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
  Future<CheckoutResult> checkout({
    required String eventId,
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  }) async {
    final result = await _client.rpc('checkout', params: {
      'p_event_id': eventId,
      'p_qty': qty,
      'p_voucher_code': voucherCode,
      'p_payment_method': paymentMethod,
      'p_buyer_name': buyerName.trim(),
      'p_buyer_email': buyerEmail.trim(),
      'p_buyer_phone': buyerPhone.trim(),
    });

    return CheckoutResult.fromRpc(Map<String, dynamic>.from(result as Map));
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

  @override
  Future<List<TransactionRecord>> fetchTransactions() async {
    final rows = await _client
        .from('transactions')
        .select(
          'id, total, payment_method, status, created_at, '
          'tickets(code), events(title)',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => TransactionRecord.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
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

  @override
  Future<Set<String>> fetchUsedVoucherCodes() async {
    final rows = await _client
        .from('voucher_redemptions')
        .select('code')
        .eq('user_id', _userId);
    return rows
        .map((row) => row['code'].toString().toUpperCase())
        .toSet();
  }

  // ── Notifikasi (P2 scaffold) ──────────────────────────────────────

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', _userId);
  }

  @override
  Future<List<String>> fetchDeviceTokens() async {
    final rows = await _client
        .from('device_tokens')
        .select('token')
        .eq('user_id', _userId);
    return rows
        .map((row) => row['token'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    String platform = 'unknown',
  }) async {
    await _client.from('device_tokens').upsert({
      'user_id': _userId,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
