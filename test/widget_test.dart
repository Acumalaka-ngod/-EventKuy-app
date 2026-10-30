import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/main.dart';

void main() {
  testWidgets('menampilkan panduan setup tanpa konfigurasi Supabase',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EventKuyApp());

    expect(find.text('Supabase belum dikonfigurasi'), findsOneWidget);
    expect(find.textContaining('schema.sql'), findsOneWidget);
    expect(find.textContaining('--dart-define'), findsOneWidget);
  });
}
