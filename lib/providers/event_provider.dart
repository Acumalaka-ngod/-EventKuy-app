import 'dart:async';

import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

class EventProvider extends ChangeNotifier {
  EventProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;

  List<Event> _events = [];
  bool _loading = false;
  bool _refreshQueued = false;
  String? _error;
  String _query = '';
  String _category = 'Semua';

  static const categories = [
    'Semua',
    'Konser',
    'Seminar',
    'Workshop',
    'Olahraga',
  ];

  List<Event> get events {
    var list = _events;
    if (_category != 'Semua') {
      list = list.where((e) => e.category == _category).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.location.toLowerCase().contains(q) ||
                e.category.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<Event> get nearby => _events.take(4).toList();

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  String get category => _category;

  /// Cari event berdasarkan ID dari daftar yang sedang dimuat.
  /// Dipakai layar detail/checkout supaya selalu memakai data stok terbaru,
  /// bukan snapshot lama yang dipegang widget.
  Event? eventById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  Future<void> loadEvents({bool force = false}) async {
    if (_loading) {
      // Jangan buang permintaan force-refresh (mis. setelah checkout) hanya
      // karena ada fetch lain yang sedang berjalan.
      if (force) _refreshQueued = true;
      return;
    }
    if (!force && _events.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _api.fetchEvents();
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _loading = false;
      notifyListeners();
      if (_refreshQueued) {
        _refreshQueued = false;
        unawaited(loadEvents(force: true));
      }
    }
  }

  /// Simpan event baru atau perubahan event yang sudah ada.
  ///
  /// Daftar lokal langsung diperbarui supaya dashboard dan halaman detail
  /// tidak perlu menunggu fetch ulang. Pemanggil tetap boleh memanggil
  /// [loadEvents] dengan `force: true` untuk rekonsiliasi.
  Future<Event> saveEvent({
    String? eventId,
    required EventDraft draft,
  }) async {
    final saved = eventId == null
        ? await _api.createEvent(draft)
        : await _api.updateEvent(eventId, draft);

    final index = _events.indexWhere((event) => event.id == saved.id);
    if (index == -1) {
      _events = [..._events, saved]
        ..sort((a, b) => a.date.compareTo(b.date));
    } else {
      final updated = [..._events];
      // `sold` dihitung backend lewat view event_stock; pertahankan nilai
      // yang sudah ditampilkan agar tidak berkedip menjadi 0.
      updated[index] = saved.copyWith(sold: _events[index].sold);
      _events = updated..sort((a, b) => a.date.compareTo(b.date));
    }

    _error = null;
    notifyListeners();
    return saved;
  }

  /// Kurangi sisa stok secara optimistis tepat setelah checkout berhasil.
  /// Backend tetap menjadi sumber kebenaran; pemanggil sebaiknya lanjut
  /// memanggil [loadEvents] dengan `force: true` untuk rekonsiliasi.
  void applySoldDelta(String eventId, int delta) {
    if (delta == 0) return;

    final index = _events.indexWhere((event) => event.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    final next = event.sold + delta;
    final sold = event.quota > 0
        ? next.clamp(0, event.quota)
        : (next < 0 ? 0 : next);
    if (sold == event.sold) return;

    final updated = [..._events];
    updated[index] = event.copyWith(sold: sold);
    _events = updated;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setCategory(String c) {
    _category = c;
    notifyListeners();
  }
}
