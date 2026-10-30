import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/ticket.dart';

/// Membuat e-tiket PDF dan membagikannya (share sheet di mobile,
/// unduhan file di web) melalui package `printing`.
class TicketPdfService {
  TicketPdfService._();

  static const _violet = PdfColor.fromInt(0xFF4B3FC3);
  static const _violetDark = PdfColor.fromInt(0xFF201C52);
  static const _ink = PdfColor.fromInt(0xFF17152C);
  static const _muted = PdfColor.fromInt(0xFF77758A);
  static const _faint = PdfColor.fromInt(0xFFAAA8B6);
  static const _border = PdfColor.fromInt(0xFFE8E7EF);
  static const _green = PdfColor.fromInt(0xFF1AA981);
  static const _amber = PdfColor.fromInt(0xFFB7791F);

  /// Nama file yang aman dipakai di Android, iOS, dan browser.
  static String fileNameFor(String code) {
    final safe = code
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'EventKuy-${safe.isEmpty ? 'Tiket' : safe}.pdf';
  }

  static Future<Uint8List> buildTicketPdf({
    required Ticket ticket,
    String attendeeName = 'Pengguna',
    String dateLocation = '',
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Manrope-Regular.ttf'),
    );
    final medium = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Manrope-Medium.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Manrope-Bold.ttf'),
    );
    final extraBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Manrope-ExtraBold.ttf'),
    );

    final status = _statusOf(ticket.status);
    final title = ticket.eventTitle.isEmpty ? 'Event EventKuy' : ticket.eventTitle;

    final doc = pw.Document(
      title: 'E-Tiket EventKuy ${ticket.code}',
      author: 'EventKuy',
      creator: 'EventKuy',
      subject: 'E-Tiket $title',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(26),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [_violetDark, _violet],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EVENTKUY',
                        style: pw.TextStyle(
                          font: extraBold,
                          color: PdfColors.white,
                          fontSize: 12,
                          letterSpacing: 1.6,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white.withAlpha(0.16),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          status.label,
                          style: pw.TextStyle(
                            font: bold,
                            color: PdfColors.white,
                            fontSize: 6.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 26),
                  pw.Text(
                    'E-TIKET',
                    style: pw.TextStyle(
                      font: medium,
                      color: PdfColors.white.withAlpha(0.62),
                      fontSize: 7.5,
                      letterSpacing: 1.3,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    maxLines: 3,
                    style: pw.TextStyle(
                      font: extraBold,
                      color: PdfColors.white,
                      fontSize: 18,
                      lineSpacing: 2,
                    ),
                  ),
                  if (dateLocation.isNotEmpty) ...[
                    pw.SizedBox(height: 9),
                    pw.Text(
                      dateLocation,
                      style: pw.TextStyle(
                        font: regular,
                        color: PdfColors.white.withAlpha(0.75),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _InfoTile(
                    label: 'PEMILIK TIKET',
                    value: attendeeName,
                    font: bold,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _InfoTile(
                    label: 'STATUS',
                    value: status.detail,
                    font: bold,
                    color: status.color,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border, width: 1),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: ticket.code,
                    width: 126,
                    height: 126,
                    drawText: false,
                    color: _ink,
                    backgroundColor: PdfColors.white,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'TICKET ID',
                    style: pw.TextStyle(
                      font: medium,
                      color: _faint,
                      fontSize: 7,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    ticket.code,
                    style: pw.TextStyle(
                      font: extraBold,
                      color: _ink,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'Tunjukkan e-tiket ini kepada petugas di pintu masuk. '
                    'QR hanya dapat digunakan satu kali.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regular,
                      color: _muted,
                      fontSize: 7.5,
                      lineSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Diterbitkan otomatis oleh EventKuy',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: medium,
                      color: _faint,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Membagikan PDF. Di web `Printing` otomatis mengunduh file.
  static Future<bool> shareTicketPdf({
    required Ticket ticket,
    String attendeeName = 'Pengguna',
    String dateLocation = '',
  }) async {
    final bytes = await buildTicketPdf(
      ticket: ticket,
      attendeeName: attendeeName,
      dateLocation: dateLocation,
    );

    return Printing.sharePdf(
      bytes: bytes,
      filename: fileNameFor(ticket.code),
      subject: 'E-Tiket EventKuy ${ticket.code}',
      body: 'E-tiket untuk ${ticket.eventTitle}.',
    );
  }

  static _TicketStatus _statusOf(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'checked_in':
        return const _TicketStatus(
          label: 'SUDAH CHECK-IN',
          detail: 'Sudah check-in',
          color: _green,
        );
      case 'paid':
        return const _TicketStatus(
          label: 'TIKET AKTIF',
          detail: 'Tiket aktif',
          color: _green,
        );
      case 'pending':
        return const _TicketStatus(
          label: 'MENUNGGU BAYAR',
          detail: 'Menunggu pembayaran',
          color: _amber,
        );
      default:
        return _TicketStatus(
          label: rawStatus.toUpperCase(),
          detail: rawStatus,
          color: _muted,
        );
    }
  }
}

class _TicketStatus {
  final String label;
  final String detail;
  final PdfColor color;

  const _TicketStatus({
    required this.label,
    required this.detail,
    required this.color,
  });
}

class _InfoTile extends pw.StatelessWidget {
  _InfoTile({
    required this.label,
    required this.value,
    required this.font,
    this.color = const PdfColor.fromInt(0xFF17152C),
  });

  final String label;
  final String value;
  final pw.Font font;
  final PdfColor color;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F8FC),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              color: const PdfColor.fromInt(0xFFAAA8B6),
              fontSize: 6.5,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 2,
            style: pw.TextStyle(
              font: font,
              color: color,
              fontSize: 10,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
