import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/notification_router.dart';

void main() {
  setUp(() => NotificationRouter.reset());
  tearDown(() => NotificationRouter.reset());

  test('meneruskan URI ke handler yang sudah terdaftar', () {
    final received = <String>[];
    NotificationRouter.setHandler(received.add);

    NotificationRouter.routeToEvent('event-1');

    expect(received, ['eventkuy://event/event-1']);
  });

  test(
    'menyimpan URI bila handler belum terdaftar lalu memutarnya saat register',
    () {
      final received = <String>[];

      NotificationRouter.routeToEvent('event-2');
      expect(received, isEmpty);

      NotificationRouter.setHandler(received.add);

      expect(received, ['eventkuy://event/event-2']);
    },
  );

  test('mengabaikan event ID kosong', () {
    final received = <String>[];
    NotificationRouter.setHandler(received.add);

    NotificationRouter.routeToEvent(null);
    NotificationRouter.routeToEvent('  ');

    expect(received, isEmpty);
  });

  test('URI tersimpan hanya sekali meski handler didaftarkan ulang', () {
    final first = <String>[];
    final second = <String>[];

    NotificationRouter.routeToEvent('event-3');
    NotificationRouter.setHandler(first.add);
    NotificationRouter.setHandler(second.add);

    expect(first, ['eventkuy://event/event-3']);
    expect(second, isEmpty);
  });
}
