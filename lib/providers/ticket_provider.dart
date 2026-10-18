import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/ticket.dart';

/// Keranjang + tiket dummy. Nanti POST /tickets/checkout Midtrans (Fase 5).
class TicketProvider extends ChangeNotifier {
  final List<Ticket> _tickets = [];

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  void buyDummy(Event event) {
    final code = 'AJG-${event.id}${DateTime.now().millisecondsSinceEpoch % 100000}';
    _tickets.add(Ticket(
      code: code,
      eventId: event.id,
      eventTitle: event.title,
      status: 'paid',
    ));
    notifyListeners();
  }

  void checkIn(String code) {
    final i = _tickets.indexWhere((t) => t.code == code);
    if (i != -1) {
      _tickets[i] = _tickets[i].copyWith(status: 'checked_in');
      notifyListeners();
    }
  }
}
