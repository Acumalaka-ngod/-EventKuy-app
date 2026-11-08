import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/screens/profile/help_center_screen.dart';

Widget _app() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const HelpCenterScreen(),
  );
}

void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('minimal 8 FAQ tampil dalam 3 kategori', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(_app());

    expect(find.text('PEMBELIAN'), findsOneWidget);
    expect(find.text('TIKET & CHECK-IN'), findsOneWidget);
    expect(find.text('AKUN'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsAtLeastNWidgets(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('accordion membuka jawaban saat pertanyaan diketuk', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.textContaining('Pilih event di Beranda'), findsNothing);

    await tester.tap(find.text('Bagaimana cara membeli tiket?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pilih event di Beranda'), findsOneWidget);

    await tester.tap(find.text('Bagaimana cara membeli tiket?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pilih event di Beranda'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pencarian menyaring pertanyaan dan jawaban', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.byKey(const ValueKey('faq-search')),
      'voucher',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Bagaimana cara memakai kode voucher?'),
      findsOneWidget,
    );
    expect(
      find.text('Bagaimana cara membeli tiket?'),
      findsNothing,
    );
    expect(find.text('TIKET & CHECK-IN'), findsNothing);
    expect(find.text('AKUN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kata kunci tanpa hasil menampilkan empty state', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.byKey(const ValueKey('faq-search')),
      'zzz-tidak-ada',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('faq-empty')), findsOneWidget);
    expect(find.text('Tidak ada pertanyaan yang cocok'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
