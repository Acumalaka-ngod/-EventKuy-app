import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';import '../core/deep_link.dart';
import '../core/formatters.dart';
import '../models/event.dart';

/// Abstraksi layanan berbagi konten EventKuy.
///
/// Implementasi produksi memakai [share_plus]. Jika gagal atau tidak tersedia,
/// fallback menyalin teks ke clipboard.
class ShareService {
  ShareService._();

  /// Hasilkan teks share lengkap untuk [event], termasuk tautan deep link.
  static String shareText(Event event) {
    final jadwal = event.timeRange.isEmpty
        ? formatTanggal(event.date)
        : '${formatTanggal(event.date)} · ${event.timeRange} WIB';

    return '${event.title}\n'
        '$jadwal\n'
        '${event.location}\n'
        'Harga tiket: ${formatRp(event.price)}\n'
        '${DeepLink.eventUri(event.id)}\n\n'
        'Cek detailnya di EventKuy!';
  }

  /// Bagikan [text] melalui share sheet sistem.
  ///
  /// Mengembalikan:
  /// - `shared` jika berhasil dibagikan lewat share sheet
  /// - `copied` jika fallback ke clipboard karena share sheet gagal
  /// - `failed` jika gagal sama sekali
  static Future<ShareResult> share(String text) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: _subjectFromText(text)),
      );
      if (result.status == ShareResultStatus.success) {
        return ShareResult.shared;
      }
    } catch (_) {
      // SharePlus tidak tersedia di platform ini.
    }
    // Fallback: salin ke clipboard bila share sheet gagal/tidak tersedia.
    await Clipboard.setData(ClipboardData(text: text));
    return ShareResult.copied;
  }

  static String _subjectFromText(String text) {
    final firstLine = text.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'EventKuy';
  }
}

/// Hasil operasi share.
enum ShareResult {
  shared,
  copied,
  failed,
}
