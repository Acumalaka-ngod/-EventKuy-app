import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import 'image_validation.dart';

/// Error upload avatar dengan pesan yang aman ditampilkan ke pengguna.
class AvatarUploadException implements Exception {
  final String message;
  const AvatarUploadException(this.message);

  @override
  String toString() => message;
}

/// Metadata gambar avatar yang sudah lolos validasi.
class AvatarImage {
  const AvatarImage({required this.extension, required this.contentType});

  final String extension;
  final String contentType;
}

/// Unggah foto profil ke Supabase Storage bucket `avatars`.
///
/// Path selalu diawali id user (`<user_id>/avatar-<timestamp>.<ext>`) supaya
/// policy Storage bisa membatasi file ke pemiliknya.
class AvatarService {
  AvatarService([this._client]);

  final SupabaseClient? _client;

  static const int maxBytes = 5 * 1024 * 1024;

  /// Hanya gambar statis yang diterima. GIF dan format lain ditolak.
  static const String formatErrorMessage =
      'Format foto harus JPG, PNG, atau WebP.';

  SupabaseClient get _supabase {
    if (_client != null) return _client;
    if (!AppConfig.hasSupabaseConfig) {
      throw const AvatarUploadException('Supabase belum dikonfigurasi.');
    }
    return Supabase.instance.client;
  }

  /// Validasi isi file, ekstensi, dan MIME sebelum menyentuh Storage.
  ///
  /// Format ditentukan dari magic bytes, bukan dari nama file, sehingga GIF
  /// yang diganti ekstensinya tetap ditolak. Ekstensi/MIME yang tidak cocok
  /// dengan isi file juga ditolak.
  static AvatarImage validateImage({
    required Uint8List bytes,
    String? extension,
    String? contentType,
  }) {
    try {
      final image = validateUploadImage(
        bytes: bytes,
        extension: extension,
        contentType: contentType,
        maxBytes: maxBytes,
        formatMessage: formatErrorMessage,
        emptyMessage: 'File foto kosong.',
        sizeMessage: 'Ukuran foto maksimal 5 MB.',
      );
      return AvatarImage(
        extension: image.extension,
        contentType: image.contentType,
      );
    } on UploadImageException catch (error) {
      throw AvatarUploadException(error.message);
    }
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final image = validateImage(
      bytes: bytes,
      extension: extension,
      contentType: contentType,
    );

    final storage = _supabase.storage.from('avatars');
    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.'
        '${image.extension}';

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: image.contentType, upsert: true),
      );
    } on StorageException catch (error) {
      throw AvatarUploadException(_friendlyStorageMessage(error));
    }

    // Bersihkan avatar lama di folder user. Kegagalan hapus tidak boleh
    // menggagalkan upload yang sudah berhasil.
    try {
      final files = await storage.list(path: userId);
      final oldPaths = files
          .map((file) => '$userId/${file.name}')
          .where((oldPath) => oldPath != path)
          .toList(growable: false);
      if (oldPaths.isNotEmpty) {
        await storage.remove(oldPaths);
      }
    } catch (_) {
      // Abaikan: file lama akan tetap ada, tetapi avatar baru tetap tampil.
    }

    return storage.getPublicUrl(path);
  }

  String _friendlyStorageMessage(StorageException error) {
    final message = error.message.toLowerCase();
    if (message.contains('bucket not found') || error.statusCode == '404') {
      return 'Storage avatar belum disiapkan. Jalankan supabase/avatars.sql.';
    }
    if (error.statusCode == '401' || error.statusCode == '403') {
      return 'Kamu tidak punya izin mengunggah foto.';
    }
    return 'Gagal mengunggah foto. Coba lagi.';
  }
}
