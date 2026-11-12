import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/services/event_image_service.dart';

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
  isA<EventImageUploadException>().having(
    (error) => error.message,
    'message',
    EventImageService.formatErrorMessage,
  ),
);

void main() {
  group('EventImageService.validateImage', () {
    test('PNG diterima', () {
      final image = EventImageService.validateImage(
        bytes: _png,
        extension: 'png',
        contentType: 'image/png',
      );

      expect(image.extension, 'png');
      expect(image.contentType, 'image/png');
    });

    test('JPEG dengan ekstensi jpeg dinormalisasi menjadi jpg', () {
      final image = EventImageService.validateImage(
        bytes: _jpeg,
        extension: 'jpeg',
        contentType: 'image/jpeg',
      );

      expect(image.extension, 'jpg');
      expect(image.contentType, 'image/jpeg');
    });

    test('WebP diterima', () {
      final image = EventImageService.validateImage(
        bytes: _webp,
        extension: 'webp',
        contentType: 'image/webp',
      );

      expect(image.extension, 'webp');
    });

    test('GIF ditolak meskipun ekstensi dan MIME mengaku gambar', () {
      expect(
        () => EventImageService.validateImage(
          bytes: _gif,
          extension: 'gif',
          contentType: 'image/gif',
        ),
        _formatError(),
      );
    });

    test('GIF yang menyamar sebagai JPG tetap ditolak', () {
      expect(
        () => EventImageService.validateImage(
          bytes: _gif,
          extension: 'jpg',
          contentType: 'image/jpeg',
        ),
        _formatError(),
      );
    });

    test('ekstensi yang tidak cocok dengan isi file ditolak', () {
      expect(
        () => EventImageService.validateImage(
          bytes: _png,
          extension: 'jpg',
          contentType: 'image/png',
        ),
        _formatError(),
      );
    });

    test('file non-gambar ditolak', () {
      expect(
        () => EventImageService.validateImage(
          bytes: _bytes('bukan gambar'.codeUnits),
          extension: 'png',
          contentType: 'image/png',
        ),
        _formatError(),
      );
    });

    test('file kosong ditolak', () {
      expect(
        () => EventImageService.validateImage(bytes: Uint8List(0)),
        throwsA(
          isA<EventImageUploadException>().having(
            (error) => error.message,
            'message',
            'File gambar kosong.',
          ),
        ),
      );
    });

    test('file lebih dari 5 MB ditolak', () {
      final oversize = Uint8List(EventImageService.maxBytes + 1)
        ..setRange(0, _png.length, _png);

      expect(
        () => EventImageService.validateImage(bytes: oversize),
        throwsA(
          isA<EventImageUploadException>().having(
            (error) => error.message,
            'message',
            'Ukuran gambar maksimal 5 MB.',
          ),
        ),
      );
    });

    test('uploadEventImage menolak GIF sebelum menyentuh Storage', () async {
      final service = EventImageService();

      await expectLater(
        service.uploadEventImage(
          userId: 'u1',
          bytes: _gif,
          extension: 'gif',
          contentType: 'image/gif',
        ),
        _formatError(),
      );
    });
  });

  group('EventImageService.pathFromPublicUrl', () {
    test('mengambil path objek dari public URL Supabase', () {
      expect(
        EventImageService.pathFromPublicUrl(
          'https://abc.supabase.co/storage/v1/object/public/event-images/'
          'u1/evt-1-123.png',
        ),
        'u1/evt-1-123.png',
      );
    });

    test('mengembalikan null untuk aset lokal', () {
      expect(
        EventImageService.pathFromPublicUrl('assets/images/event_sound.jpg'),
        isNull,
      );
    });

    test('mengembalikan null untuk URL host lain', () {
      expect(
        EventImageService.pathFromPublicUrl(
          'https://example.com/event-images/poster.png',
        ),
        isNull,
      );
    });

    test('mengembalikan null bila bucket tanpa nama file', () {
      expect(
        EventImageService.pathFromPublicUrl(
          'https://abc.supabase.co/storage/v1/object/public/event-images',
        ),
        isNull,
      );
    });
  });
}
