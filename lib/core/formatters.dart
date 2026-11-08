import 'package:intl/intl.dart';

/// Helper format tanggal dan angka EventKuy.
///
/// Semua layar memakai helper ini agar locale `id_ID` konsisten dan tidak ada
/// `DateFormat`/`NumberFormat` yang ditulis ulang di UI.
String formatRp(int value) => value == 0
    ? 'Gratis'
    : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);

/// Tanggal lengkap bahasa Indonesia, contoh: 12 Juli 2025.
/// Fallback ke format Inggris bila data locale belum diinisialisasi
/// (misalnya saat widget test).
String formatTanggal(DateTime date) {
  try {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  } catch (_) {
    return DateFormat('d MMMM yyyy').format(date);
  }
}

/// Tanggal pendek bahasa Indonesia, contoh: 12 Jul 2025.
String formatTanggalSingkat(DateTime date) {
  try {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  } catch (_) {
    return DateFormat('d MMM yyyy').format(date);
  }
}

/// Nama bulan pendek huruf besar, contoh: JUL.
String formatBulanPendek(DateTime date) {
  try {
    return DateFormat('MMM', 'id_ID').format(date).toUpperCase();
  } catch (_) {
    return DateFormat('MMM').format(date).toUpperCase();
  }
}
