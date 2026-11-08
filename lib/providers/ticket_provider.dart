import 'dart:async';

import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../models/check_in_result.dart';
import '../models/checkout_result.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

/// Tiket user + checkout (RPC `checkout`) + check-in (RPC `check_in_ticket`).
///
/// Selain memuat data, provider ini memantau perubahan tiket lewat
/// [EventKuyApi.watchTickets] (Supabase Realtime) sehingga layar attendee
/// ikut ter-refresh saat organizer melakukan check-in. Jika realtime tidak
/// tersedia/putus, polling berkala dipakai sebagai fallback.
class TicketProvider extends ChangeNotifier {
  TicketProvider({
    EventKuyApi? api,
    this.pollInterval = const Duration(seconds: 5),
  }) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;

  /// Interval polling fallback saat realtime tidak tersedia.
  /// `null` = tanpa polling (dipakai widget test).
  final Duration? pollInterval;
  final List<Ticket> _tickets = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<void>? _watchSub;
  Timer? _reloadDebounce;
  Timer? _pollTimer;
  bool _disposed = false;
  Ticket? _lastCheckIn;

  List<Ticket> get tickets => List.unmodifiable(_tickets);
  bool get loading => _loading;
  String? get error => _error;

  /// Tiket yang statusnya baru berubah menjadi `checked_in` saat dipantau.
  /// Dipakai layar untuk menampilkan notifikasi, lalu diakui lewat
  /// [acknowledgeCheckIn].
  Ticket? get lastCheckIn => _lastCheckIn;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final tickets = await _api.fetchTickets();
      if (_disposed) return;
      _tickets
        ..clear()
        ..addAll(tickets);
    } catch (error) {
      if (_disposed) return;
      _error = friendlyError(error);
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Mulai memantau perubahan tiket. Aman dipanggil berkali-kali.
  ///
  /// Realtime dipakai lebih dulu. Kalau channel gagal/berhenti (mis. tabel
  /// belum diaktifkan di publication `supabase_realtime`), polling berkala
  /// otomatis mengambil alih supaya layar tetap ter-refresh.
  void startWatching() {
    if (_disposed) return;
    _watchSub ??= _api.watchTickets().listen(
      (_) => _scheduleReload(),
      onError: (_) => _startPolling(),
      onDone: _startPolling,
      cancelOnError: false,
    );
  }

  void _startPolling() {
    if (_disposed) return;
    final interval = pollInterval;
    if (interval == null) return;
    refresh();
    _pollTimer ??= Timer.periodic(interval, (_) => refresh());
  }

  /// Berhenti memantau (dipanggil saat layar tiket ditutup).
  void stopWatching() {
    _watchSub?.cancel();
    _watchSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _reloadDebounce?.cancel();
    _reloadDebounce = null;
  }

  /// Muat ulang tanpa indikator loading (dipakai realtime/polling/resume app).
  Future<void> refresh() async {
    if (_disposed) return;
    try {
      final tickets = await _api.fetchTickets();
      if (_disposed) return;
      _error = null;
      _applyTickets(tickets);
    } catch (_) {
      // Abaikan: jaringan bermasalah, coba lagi pada putaran berikutnya.
    }
  }

  void _scheduleReload() {
    if (_disposed) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), refresh);
  }

  /// Terapkan data baru dan deteksi tiket yang baru saja di-check-in
  /// (perubahan `paid`/`pending` -> `checked_in`).
  void _applyTickets(List<Ticket> fresh) {
    Ticket? justCheckedIn;
    if (_tickets.isNotEmpty) {
      for (final ticket in fresh) {
        if (ticket.status.toLowerCase() != 'checked_in') continue;
        String? previousStatus;
        for (final previous in _tickets) {
          if (previous.code == ticket.code) {
            previousStatus = previous.status.toLowerCase();
            break;
          }
        }
        if (previousStatus == null || previousStatus != 'checked_in') {
          justCheckedIn = ticket;
          break;
        }
      }
    }

    _tickets
      ..clear()
      ..addAll(fresh);
    if (justCheckedIn != null) _lastCheckIn = justCheckedIn;
    notifyListeners();
  }

  /// Tandai notifikasi check-in sudah ditampilkan.
  void acknowledgeCheckIn() {
    _lastCheckIn = null;
  }

  Future<CheckoutResult> checkout(
    Event event, {
    int qty = 1,
    String? voucherCode,
    String paymentMethod = 'GoPay',
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  }) async {
    final result = await _api.checkout(
      eventId: event.id,
      qty: qty,
      voucherCode: voucherCode,
      paymentMethod: paymentMethod,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
    );
    _tickets.insertAll(0, result.tickets);
    notifyListeners();
    return result;
  }

  Future<Set<String>> fetchUsedVoucherCodes() => _api.fetchUsedVoucherCodes();

  Future<CheckInResult> checkIn(String code) async {
    final result = await _api.checkIn(code);
    final i = _tickets.indexWhere(
      (t) => t.code.toUpperCase() == code.trim().toUpperCase(),
    );
    if (i != -1) {
      _tickets[i] = _tickets[i].copyWith(status: 'checked_in');
      notifyListeners();
    }
    return result;
  }

  Future<List<Ticket>> ticketsForEvent(String eventId) =>
      _api.fetchEventTickets(eventId);

  Future<Voucher?> fetchVoucher(String code) => _api.fetchVoucher(code);

  void clear() {
    stopWatching();
    _tickets.clear();
    _lastCheckIn = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopWatching();
    super.dispose();
  }
}
