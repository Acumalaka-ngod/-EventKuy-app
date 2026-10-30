import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/supabase_api.dart';

class EventProvider extends ChangeNotifier {
  EventProvider({EventKuyApi? api}) : _api = api ?? SupabaseApi();

  final EventKuyApi _api;

  List<Event> _events = [];
  bool _loading = false;
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
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<Event> get nearby => _events.take(4).toList();

  bool get loading => _loading;
  String? get error => _error;
  String get category => _category;

  Future<void> loadEvents({bool force = false}) async {
    if (_loading || (!force && _events.isNotEmpty)) return;
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
    }
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
