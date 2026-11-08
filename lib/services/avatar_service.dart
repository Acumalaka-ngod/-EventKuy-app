import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

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

  static const _pngFormat = _ImageFormat(
    extension: 'png',
    contentType: 'image/png',
    extensions: {'png'},
  );
  static const _jpegFormat = _ImageFormat(
    extension: 'jpg',
    contentType: 'image/jpeg',
    extensions: {'jpg', 'jpeg'},
  );
  static const _webpFormat = _ImageFormat(
    extension: 'webp',
    contentType: 'image/webp',
    extensions: {'webp'},
  );

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
    if (bytes.isEmpty) {
      throw const AvatarUploadException('File foto kosong.');
    }
    if (bytes.length > maxBytes) {
      throw const AvatarUploadException('Ukuran foto maksimal 5 MB.');
    }

    final detected = _detectFormat(bytes);
    if (detected == null) {
      throw const AvatarUploadException(formatErrorMessage);
    }

    final requestedExtension = _normalizeExtension(extension);
    if (requestedExtension.isNotEmpty &&
        !detected.extensions.contains(requestedExtension)) {
      throw const AvatarUploadException(formatErrorMessage);
    }

    final mime = (contentType ?? '')
        .trim()
        .toLowerCase()
        .split(';')
        .first
        .trim();
    if (mime.isNotEmpty && mime != detected.contentType) {
      throw const AvatarUploadException(formatErrorMessage);
    }

    return AvatarImage(
      extension: detected.extension,
      contentType: detected.contentType,
    );
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

  static _ImageFormat? _detectFormat(Uint8List bytes) {
    if (_startsWith(bytes, const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ])) {
      return _pngFormat;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return _jpegFormat;
    }
    if (bytes.length >= 12 &&
        _matchesAscii(bytes, 0, 'RIFF') &&
        _matchesAscii(bytes, 8, 'WEBP')) {
      return _webpFormat;
    }
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  static bool _matchesAscii(Uint8List bytes, int offset, String ascii) {
    if (bytes.length < offset + ascii.length) return false;
    for (var i = 0; i < ascii.length; i++) {
      if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
    }
    return true;
  }

  static String _normalizeExtension(String? extension) {
    return (extension ?? '').trim().toLowerCase().replaceFirst(
      RegExp(r'^\.+'),
      '',
    );
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

class _ImageFormat {
  const _ImageFormat({
    required this.extension,
    required this.contentType,
    required this.extensions,
  });

  final String extension;
  final String contentType;
  final Set<String> extensions;
}
