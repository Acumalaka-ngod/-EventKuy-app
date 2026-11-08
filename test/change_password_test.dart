import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/screens/profile/change_password_screen.dart';

class _FakeAuthProvider extends AuthProvider {
  String? result;
  int calls = 0;
  String? currentPassword;
  String? newPassword;

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls += 1;
    this.currentPassword = currentPassword;
    this.newPassword = newPassword;
    return result;
  }
}

Widget _app(AuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const ChangePasswordScreen(),
    ),
  );
}

Future<void> _fill(
  WidgetTester tester, {
  String current = '',
  String next = '',
  String confirm = '',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('current-password')),
    current,
  );
  await tester.enterText(find.byKey(const ValueKey('new-password')), next);
  await tester.enterText(
    find.byKey(const ValueKey('confirm-password')),
    confirm,
  );
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('change-password-submit')));
  await tester.pump();
}

void main() {
  testWidgets('password saat ini kosong ditolak', (tester) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(tester, next: 'passwordbaru', confirm: 'passwordbaru');
    await _submit(tester);

    expect(find.text('Masukkan password saat ini.'), findsOneWidget);
    expect(auth.calls, 0);
  });

  testWidgets('password baru kurang dari 8 karakter ditolak', (tester) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'lamasekali',
      next: 'pendek',
      confirm: 'pendek',
    );
    await _submit(tester);

    expect(find.text('Password baru minimal 8 karakter.'), findsOneWidget);
    expect(auth.calls, 0);
  });

  testWidgets('konfirmasi tidak sama ditolak', (tester) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'lamasekali',
      next: 'passwordbaru',
      confirm: 'passwordlain',
    );
    await _submit(tester);

    expect(find.text('Konfirmasi password tidak cocok.'), findsOneWidget);
    expect(auth.calls, 0);
  });

  testWidgets('password baru sama dengan lama ditolak', (tester) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'passwordlama',
      next: 'passwordlama',
      confirm: 'passwordlama',
    );
    await _submit(tester);

    expect(
      find.text('Password baru harus berbeda dari password lama.'),
      findsOneWidget,
    );
    expect(auth.calls, 0);
  });

  testWidgets('field password punya label yang terbaca pembaca layar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(_FakeAuthProvider()));

      for (final entry in const {
        'current-password': 'Password Saat Ini',
        'new-password': 'Password Baru',
        'confirm-password': 'Konfirmasi Password Baru',
      }.entries) {
        final node = tester.getSemantics(find.byKey(ValueKey(entry.key)));
        expect(node.label, contains(entry.value), reason: entry.key);
        expect(
          node.getSemanticsData().flagsCollection.isTextField,
          isTrue,
          reason: entry.key,
        );
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('validasi inline memfokuskan field pertama yang invalid', (
    tester,
  ) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(tester, next: 'passwordbaru', confirm: 'passwordbaru');
    await _submit(tester);

    final current = tester.widget<TextField>(
      find.byKey(const ValueKey('current-password')),
    );
    expect(current.decoration?.errorText, 'Masukkan password saat ini.');
    expect(current.focusNode?.hasFocus, isTrue);
    expect(find.byType(SnackBar), findsNothing);
    expect(auth.calls, 0);
  });

  testWidgets('konfirmasi tidak sama memfokuskan field konfirmasi', (
    tester,
  ) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'lamasekali',
      next: 'passwordbaru',
      confirm: 'passwordlain',
    );
    await _submit(tester);

    final confirm = tester.widget<TextField>(
      find.byKey(const ValueKey('confirm-password')),
    );
    expect(confirm.decoration?.errorText, 'Konfirmasi password tidak cocok.');
    expect(confirm.focusNode?.hasFocus, isTrue);
    expect(find.byType(SnackBar), findsNothing);
    expect(auth.calls, 0);
  });

  testWidgets('error server tampil inline tanpa SnackBar', (tester) async {
    final auth = _FakeAuthProvider()..result = 'Password saat ini salah.';
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'salah',
      next: 'passwordbaru',
      confirm: 'passwordbaru',
    );
    await _submit(tester);
    await tester.pump();

    expect(find.text('Password saat ini salah.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('current-password')))
          .controller
          ?.text,
      'salah',
    );
  });

  testWidgets('sukses mengirim password dan mengosongkan form', (tester) async {
    final auth = _FakeAuthProvider();
    await tester.pumpWidget(_app(auth));

    await _fill(
      tester,
      current: 'passwordlama',
      next: 'passwordbaru',
      confirm: 'passwordbaru',
    );
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(auth.calls, 1);
    expect(auth.currentPassword, 'passwordlama');
    expect(auth.newPassword, 'passwordbaru');
    expect(find.text('Password berhasil diubah.'), findsOneWidget);

    for (final key in const [
      'current-password',
      'new-password',
      'confirm-password',
    ]) {
      final field = tester.widget<TextField>(find.byKey(ValueKey(key)));
      expect(field.controller?.text, isEmpty, reason: 'field $key');
    }
  });

  testWidgets(
    'error password lama salah ditampilkan dan form tidak dikosongkan',
    (tester) async {
      final auth = _FakeAuthProvider()..result = 'Password saat ini salah.';
      await tester.pumpWidget(_app(auth));

      await _fill(
        tester,
        current: 'salah',
        next: 'passwordbaru',
        confirm: 'passwordbaru',
      );
      await _submit(tester);

      expect(find.text('Password saat ini salah.'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('current-password')),
      );
      expect(field.controller?.text, 'salah');
    },
  );

  testWidgets('toggle password mengubah tooltip dan label semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(_FakeAuthProvider()));

      final toggle = find.descendant(
        of: find.byKey(const ValueKey('current-password')),
        matching: find.byType(IconButton),
      );
      Finder toggleLabel(String label) => find.descendant(
        of: find.byKey(const ValueKey('current-password')),
        matching: find.bySemanticsLabel(label),
      );

      expect(toggle, findsOneWidget);
      expect(tester.widget<IconButton>(toggle).tooltip, 'Lihat password');
      expect(toggleLabel('Lihat password'), findsOneWidget);
      expect(tester.getSize(toggle).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));

      await tester.tap(toggle);
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('current-password')),
      );
      expect(field.obscureText, isFalse);
      expect(tester.widget<IconButton>(toggle).tooltip, 'Sembunyikan password');
      expect(toggleLabel('Sembunyikan password'), findsOneWidget);
      expect(toggleLabel('Lihat password'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
