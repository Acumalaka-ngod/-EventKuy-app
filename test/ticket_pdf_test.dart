import 'dart:convert';

import 'package:eventkuy/models/ticket.dart';
import 'package:eventkuy/services/ticket_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ticket = Ticket(
    code: 'EVK-PDF001',
    eventId: '11111111-1111-4111-8111-000000000001',
    eventTitle: 'Sound of Tomorrow',
    status: 'paid',
  );

  group('TicketPdfService — pembuatan e-tiket PDF', () {
    test('menghasilkan berkas PDF yang valid', () async {
      final bytes = await TicketPdfService.buildTicketPdf(
        ticket: ticket,
        attendeeName: 'Andi Pratama',
        dateLocation: '24 Oktober 2026 · Istora Senayan',
      );

      expect(bytes.length, greaterThan(1000));
      expect(ascii.decode(bytes.sublist(0, 5)), startsWith('%PDF-'));
    });

    test('nama berkas aman dan konsisten', () {
      expect(
        TicketPdfService.fileNameFor('EVK-PDF001'),
        'EventKuy-EVK-PDF001.pdf',
      );
      expect(
        TicketPdfService.fileNameFor(' EVK / 001 '),
        'EventKuy-EVK-001.pdf',
      );
    });

    test('status checked-in tetap dapat dibuat', () async {
      final bytes = await TicketPdfService.buildTicketPdf(
        ticket: ticket.copyWith(status: 'checked_in'),
        attendeeName: 'Andi Pratama',
      );

      expect(bytes.length, greaterThan(1000));
    });
  });
}
