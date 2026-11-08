import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/screens/home/home_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _user = AppUser(id: 'u1', name: 'Siti Rahma', email: 'siti@example.com');

Widget _app(AuthProvider auth, EventProvider events) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<EventProvider>.value(value: events),
      ChangeNotifierProvider(
        create: (_) => FavoriteProvider(api: MockApiService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
  );
}

void main() {
  testWidgets('avatar dan notifikasi beranda punya label serta target 48', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final events = EventProvider(api: MockApiService());
      await tester.runAsync(() => events.loadEvents());

      await tester.pumpWidget(_app(AuthProvider(initialUser: _user), events));
      await tester.pump();

      final profile = find.bySemanticsLabel('Buka profil');
      expect(profile, findsOneWidget);
      expect(tester.getSize(profile).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(profile).height, greaterThanOrEqualTo(48));

      final notification = find.bySemanticsLabel('Notifikasi');
      expect(notification, findsOneWidget);
      expect(tester.getSize(notification).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(notification).height, greaterThanOrEqualTo(48));

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
