import 'package:flutter_test/flutter_test.dart';

import 'package:ajangin/main.dart';

void main() {
  testWidgets('AjangIn boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AjangInApp());
    expect(find.text('AJANGIN'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Setelah splash, harus masuk Login atau MainNavigation
    expect(find.text('AJANGIN'), findsWidgets);
  });
}
