import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import 'image_validation.dart';

/// Error upload gambar event dengan pesan yang aman ditampilkan.
class EventImageUploadException implements Exception {
  const EventImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kontrak upload gambar event. Dipisahkan agar widget test bisa memakai
/// implementasi palsu tanpa menyentuh Supabase Storage.
abstract class EventImageUploader {
  Future<String> uploadEventImage({
    required String userId,
    String? eventId,
    required Uint8List bytes,
    String? extension,
    String? contentType,
  });

  /// Hapus file lama. Implementasi produksi mengabaikan kegagalan karena
  /// file yatim tidak boleh menggagalkan penyimpanan event.
  Future<void> deleteImage(String url);
}

/// Unggah poster event ke Supabase Storage bucket `event-images`.
///
/// Path memakai id user di depan (`<user_id>/<event>-<timestamp>.<ext>`)
/// supaya mudah ditelusuri dan dibersihkan.
class EventImageService implements EventImageUploader {
  EventImageService([this._client]);

  final SupabaseClient? _client;

  static const String bucket = 'event-images';
  static const int maxBytes = 5 * 1024 * 1024;

  static const String formatErrorMessage =
      'Format gambar harus JPG, PNG, atau WebP.';

  SupabaseClient get _supabase {
    if (_client != null) return _client;
    if (!AppConfig.hasSupabaseConfig) {
      throw const EventImageUploadException('Supabase belum dikonfigurasi.');
    }
    return Supabase.instance.client;
  }

  static UploadImageFormat validateImage({
    required Uint8List bytes,
    String? extension,
    String? contentType,
  }) {
    try {
      return validateUploadImage(
        bytes: bytes,
        extension: extension,
        contentType: contentType,
        maxBytes: maxBytes,
        formatMessage: formatErrorMessage,
        emptyMessage: 'File gambar kosong.',
        sizeMessage: 'Ukuran gambar maksimal 5 MB.',
      );
    } on UploadImageException catch (error) {
      throw EventImageUploadException(error.message);
    }
  }

  @override
  Future<String> uploadEventImage({
    required String userId,
    String? eventId,
    required Uint8List bytes,
    String? extension,
    String? contentType,
  }) async {
    final image = validateImage(
      bytes: bytes,
      extension: extension,
      contentType: contentType,
    );

    final storage = _supabase.storage.from(bucket);
    final owner = eventId ?? 'baru';
    final path =
        '$userId/$owner-${DateTime.now().millisecondsSinceEpoch}.'
        '${image.extension}';

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: image.contentType, upsert: true),
      );
    } on StorageException catch (error) {
      throw EventImageUploadException(_friendlyStorageMessage(error));
    }

    return storage.getPublicUrl(path);
  }

  @override
  Future<void> deleteImage(String url) async {
    final path = pathFromPublicUrl(url);
    if (path == null) return;
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (_) {
      // Abaikan: file lama akan tetap ada, tetapi gambar baru tetap tampil.
    }
  }

  /// Ambil path objek dari public URL Supabase Storage.
  /// Mengembalikan null untuk aset lokal atau URL dari host lain.
  static String? pathFromPublicUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) return null;

    final marker = '/storage/v1/object/public/$bucket/';
    final index = uri.path.indexOf(marker);
    if (index == -1) return null;

    final path = uri.path.substring(index + marker.length);
    return path.isEmpty ? null : path;
  }

  String _friendlyStorageMessage(StorageException error) {
    final message = error.message.toLowerCase();
    if (message.contains('bucket not found') || error.statusCode == '404') {
      return 'Storage gambar event belum disiapkan. '
          'Jalankan supabase/storage.sql.';
    }
    if (error.statusCode == '401' || error.statusCode == '403') {
      return 'Kamu tidak punya izin mengunggah gambar event.';
    }
    return 'Gagal mengunggah gambar. Coba lagi.';
  }
}
