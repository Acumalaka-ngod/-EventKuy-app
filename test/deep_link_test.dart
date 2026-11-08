import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/deep_link.dart';

void main() {
  group('DeepLink.eventUri', () {
    test('buat tautan custom scheme', () {
      expect(
        DeepLink.eventUri('11111111-1111-4111-8111-000000000001'),
        'eventkuy://event/11111111-1111-4111-8111-000000000001',
      );
    });
  });

  group('DeepLink.eventIdFromUri', () {
    test('custom scheme eventkuy://event/<id>', () {
      expect(
        DeepLink.eventIdFromUri(
          'eventkuy://event/11111111-1111-4111-8111-000000000001',
        ),
        '11111111-1111-4111-8111-000000000001',
      );
    });

    test('web hash /#/event/<id>', () {
      expect(
        DeepLink.eventIdFromUri(
          'https://eventkuy.id/#/event/11111111-1111-4111-8111-000000000001',
        ),
        '11111111-1111-4111-8111-000000000001',
      );
    });

    test('web hash dengan query parameter', () {
      expect(
        DeepLink.eventIdFromUri(
          'https://eventkuy.id/#/event/abc-123?source=wa',
        ),
        'abc-123',
      );
    });

    test('web path fallback /event/<id>', () {
      expect(
        DeepLink.eventIdFromUri('https://eventkuy.id/event/xyz-789'),
        'xyz-789',
      );
    });

    test('null mengembalikan null', () {
      expect(DeepLink.eventIdFromUri(null), isNull);
    });

    test('string kosong mengembalikan null', () {
      expect(DeepLink.eventIdFromUri(''), isNull);
    });

    test('URL non-event mengembalikan null', () {
      expect(DeepLink.eventIdFromUri('https://eventkuy.id/'), isNull);
      expect(DeepLink.eventIdFromUri('https://example.com/'), isNull);
      expect(DeepLink.eventIdFromUri('eventkuy://other/123'), isNull);
    });
  });

  group('DeepLink.isEventLink', () {
    test('true untuk custom scheme event', () {
      expect(
        DeepLink.isEventLink('eventkuy://event/abc-123'),
        isTrue,
      );
    });

    test('true untuk web hash event', () {
      expect(
        DeepLink.isEventLink('https://eventkuy.id/#/event/abc-123'),
        isTrue,
      );
    });

    test('false untuk URL non-event', () {
      expect(DeepLink.isEventLink('https://eventkuy.id/'), isFalse);
      expect(DeepLink.isEventLink(null), isFalse);
    });
  });
}
