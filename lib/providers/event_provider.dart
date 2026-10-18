import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/mock_api_service.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];
  bool _loading = false;
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
  String get category => _category;

  Future<void> loadEvents() async {
    if (_events.isNotEmpty) return;
    _loading = true;
    notifyListeners();
    // TODO Fase 3: ganti MockApiService -> ApiService GET /events
    _events = await MockApiService.fetchEvents();
    _loading = false;
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
