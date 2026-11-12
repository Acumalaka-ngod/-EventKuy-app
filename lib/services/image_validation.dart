import 'dart:typed_data';

/// Error validasi gambar unggahan dengan pesan yang aman ditampilkan.
class UploadImageException implements Exception {
  const UploadImageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Metadata gambar yang sudah lolos validasi.
class UploadImageFormat {
  const UploadImageFormat({
    required this.extension,
    required this.contentType,
  });

  final String extension;
  final String contentType;
}

/// Validasi gambar statis berdasarkan isi file (magic bytes).
///
/// Format ditentukan dari isi file, bukan dari nama, sehingga GIF yang
/// diganti ekstensinya tetap ditolak. Ekstensi/MIME yang tidak cocok dengan
/// isi file juga ditolak.
UploadImageFormat validateUploadImage({
  required Uint8List bytes,
  String? extension,
  String? contentType,
  int maxBytes = 5 * 1024 * 1024,
  String formatMessage = 'Format gambar harus JPG, PNG, atau WebP.',
  String emptyMessage = 'File gambar kosong.',
  String sizeMessage = 'Ukuran gambar maksimal 5 MB.',
}) {
  if (bytes.isEmpty) {
    throw UploadImageException(emptyMessage);
  }
  if (bytes.length > maxBytes) {
    throw UploadImageException(sizeMessage);
  }

  final detected = _detectFormat(bytes);
  if (detected == null) {
    throw UploadImageException(formatMessage);
  }

  final requestedExtension = _normalizeExtension(extension);
  if (requestedExtension.isNotEmpty &&
      !detected.extensions.contains(requestedExtension)) {
    throw UploadImageException(formatMessage);
  }

  final mime = (contentType ?? '')
      .trim()
      .toLowerCase()
      .split(';')
      .first
      .trim();
  if (mime.isNotEmpty && mime != detected.contentType) {
    throw UploadImageException(formatMessage);
  }

  return UploadImageFormat(
    extension: detected.extension,
    contentType: detected.contentType,
  );
}

const _pngFormat = _ImageFormat(
  extension: 'png',
  contentType: 'image/png',
  extensions: {'png'},
);
const _jpegFormat = _ImageFormat(
  extension: 'jpg',
  contentType: 'image/jpeg',
  extensions: {'jpg', 'jpeg'},
);
const _webpFormat = _ImageFormat(
  extension: 'webp',
  contentType: 'image/webp',
  extensions: {'webp'},
);

_ImageFormat? _detectFormat(Uint8List bytes) {
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

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

bool _matchesAscii(Uint8List bytes, int offset, String ascii) {
  if (bytes.length < offset + ascii.length) return false;
  for (var i = 0; i < ascii.length; i++) {
    if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

String _normalizeExtension(String? extension) {
  return (extension ?? '').trim().toLowerCase().replaceFirst(
    RegExp(r'^\.+'),
    '',
  );
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
