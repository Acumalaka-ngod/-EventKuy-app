import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:eventkuy/core/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });
  group('formatRp', () {
    test('nol menjadi Gratis', () {
      expect(formatRp(0), 'Gratis');
    });

    test('format rupiah Indonesia', () {
      expect(formatRp(750000), 'Rp 750.000');
    });

    test('format angka kecil', () {
      expect(formatRp(150000), 'Rp 150.000');
    });
  });

  group('formatTanggal', () {
    test('format lengkap bahasa Indonesia', () {
      expect(
        formatTanggal(DateTime(2025, 7, 12)),
        '12 Juli 2025',
      );
    });

    test('bulan Januari', () {
      expect(formatTanggal(DateTime(2026, 1, 8)), '8 Januari 2026');
    });
  });

  group('formatTanggalSingkat', () {
    test('format pendek bahasa Indonesia', () {
      expect(
        formatTanggalSingkat(DateTime(2025, 7, 12)),
        '12 Jul 2025',
      );
    });

    test('bulan Januari', () {
      expect(formatTanggalSingkat(DateTime(2026, 1, 8)), '8 Jan 2026');
    });
  });

  group('formatBulanPendek', () {
    test('nama bulan huruf besar', () {
      expect(formatBulanPendek(DateTime(2025, 7, 12)), 'JUL');
    });

    test('Januari menjadi JAN', () {
      expect(formatBulanPendek(DateTime(2026, 1, 8)), 'JAN');
    });
  });
}
