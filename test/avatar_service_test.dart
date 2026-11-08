import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/services/avatar_service.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

final _png = _bytes([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature PNG
  0x00, 0x00, 0x00, 0x0D,
]);

final _jpeg = _bytes([
  0xFF, 0xD8, 0xFF, 0xE0, // SOI + APP0
  0x00, 0x10, 0x4A, 0x46,
]);

final _webp = _bytes([
  ...'RIFF'.codeUnits,
  0x24,
  0x00,
  0x00,
  0x00,
  ...'WEBP'.codeUnits,
  ...'VP8 '.codeUnits,
  0x00,
  0x00,
  0x00,
  0x00,
]);

final _gif = _bytes([...'GIF89a'.codeUnits, 0x01, 0x00, 0x01, 0x00]);

Matcher _formatError() => throwsA(
  isA<AvatarUploadException>().having(
    (error) => error.message,
    'message',
    AvatarService.formatErrorMessage,
  ),
);

void main() {
  group('AvatarService.validateImage', () {
    test('PNG diterima dan metadata dinormalisasi', () {
      final image = AvatarService.validateImage(
        bytes: _png,
        extension: 'png',
        contentType: 'image/png',
      );

      expect(image.extension, 'png');
      expect(image.contentType, 'image/png');
    });

    test('JPEG dengan ekstensi jpeg dinormalisasi menjadi jpg', () {
      final image = AvatarService.validateImage(
        bytes: _jpeg,
        extension: 'jpeg',
        contentType: 'image/jpeg',
      );

      expect(image.extension, 'jpg');
      expect(image.contentType, 'image/jpeg');
    });

    test('WebP diterima', () {
      final image = AvatarService.validateImage(
        bytes: _webp,
        extension: 'webp',
        contentType: 'image/webp',
      );

      expect(image.extension, 'webp');
      expect(image.contentType, 'image/webp');
    });

    test('metadata boleh kosong karena dideteksi dari isi file', () {
      final image = AvatarService.validateImage(bytes: _png);

      expect(image.extension, 'png');
      expect(image.contentType, 'image/png');
    });

    test('GIF ditolak meskipun ekstensi dan MIME mengaku gambar', () {
      expect(
        () => AvatarService.validateImage(
          bytes: _gif,
          extension: 'gif',
          contentType: 'image/gif',
        ),
        _formatError(),
      );
    });

    test('GIF yang menyamar sebagai JPG tetap ditolak', () {
      expect(
        () => AvatarService.validateImage(
          bytes: _gif,
          extension: 'jpg',
          contentType: 'image/jpeg',
        ),
        _formatError(),
      );
    });

    test('ekstensi yang tidak cocok dengan isi file ditolak', () {
      expect(
        () => AvatarService.validateImage(
          bytes: _png,
          extension: 'jpg',
          contentType: 'image/png',
        ),
        _formatError(),
      );
    });

    test('MIME yang tidak cocok dengan isi file ditolak', () {
      expect(
        () => AvatarService.validateImage(
          bytes: _png,
          extension: 'png',
          contentType: 'image/jpeg',
        ),
        _formatError(),
      );
    });

    test('file non-gambar ditolak', () {
      expect(
        () => AvatarService.validateImage(
          bytes: _bytes('bukan gambar'.codeUnits),
          extension: 'png',
          contentType: 'image/png',
        ),
        _formatError(),
      );
    });

    test('file kosong ditolak', () {
      expect(
        () => AvatarService.validateImage(bytes: Uint8List(0)),
        throwsA(
          isA<AvatarUploadException>().having(
            (error) => error.message,
            'message',
            'File foto kosong.',
          ),
        ),
      );
    });

    test('file lebih dari 5 MB ditolak', () {
      final oversize = Uint8List(AvatarService.maxBytes + 1)
        ..setRange(0, _png.length, _png);

      expect(
        () => AvatarService.validateImage(bytes: oversize),
        throwsA(
          isA<AvatarUploadException>().having(
            (error) => error.message,
            'message',
            'Ukuran foto maksimal 5 MB.',
          ),
        ),
      );
    });

    test('file tepat 5 MB masih diterima', () {
      final maxSize = Uint8List(AvatarService.maxBytes)
        ..setRange(0, _png.length, _png);

      expect(
        AvatarService.validateImage(bytes: maxSize).contentType,
        'image/png',
      );
    });
  });

  test('uploadAvatar menolak GIF sebelum menyentuh Storage', () async {
    final service = AvatarService();

    await expectLater(
      service.uploadAvatar(
        userId: 'u1',
        bytes: _gif,
        extension: 'gif',
        contentType: 'image/gif',
      ),
      _formatError(),
    );
  });
}
