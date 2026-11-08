import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/auth/login_screen.dart';
import 'package:eventkuy/screens/auth/register_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/form_error_banner.dart';

class _FailingAuth extends AuthProvider {
  @override
  Future<String?> login(String email, String password) async {
    return 'Email atau password salah.';
  }

  @override
  Future<String?> register(String name, String email, String password) async {
    return 'Email sudah terdaftar.';
  }

  @override
  Future<String?> resetPassword(String email) async {
    return 'Gagal mengirim email reset.';
  }
}

Widget _app({required Widget child, AuthProvider? auth}) {
  final api = MockApiService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider(
        create: (_) => TicketProvider(api: api, pollInterval: null),
      ),
      ChangeNotifierProvider(create: (_) => FavoriteProvider(api: api)),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

Future<void> _pumpLogin(WidgetTester tester, {AuthProvider? auth}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(child: const LoginScreen(), auth: auth));
  await tester.pump();
}

Future<void> _pumpRegister(WidgetTester tester, {AuthProvider? auth}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(child: const RegisterScreen(), auth: auth));
  await tester.pump();
}

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'siti@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.pump();
}

Future<void> _fillRegister(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Siti Rahma');
  await tester.enterText(find.byType(TextFormField).at(1), 'siti@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'password123');
  await tester.enterText(find.byType(TextFormField).at(3), 'password123');
  await tester.pump();
}

void main() {
  group('Login', () {
    testWidgets('field kosong menampilkan error inline', (tester) async {
      await _pumpLogin(tester);

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Password wajib diisi.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('email tidak valid ditolak inline', (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'siti@');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid.'), findsOneWidget);
    });

    testWidgets('error server tampil di banner, bukan SnackBar', (
      tester,
    ) async {
      await _pumpLogin(tester, auth: _FailingAuth());
      await _fillLogin(tester);

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.byType(FormErrorBanner), findsOneWidget);
      expect(find.text('Email atau password salah.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('checkbox, link, autofill, dan toggle password sesuai', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpLogin(tester);

        final remember = find.byType(Checkbox);
        expect(tester.getSize(remember).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(remember).height, greaterThanOrEqualTo(48));

        final forgot = find.widgetWithText(TextButton, 'Lupa Password?');
        expect(tester.getSize(forgot).height, greaterThanOrEqualTo(48));

        final register = find.widgetWithText(TextButton, 'Daftar Sekarang');
        expect(tester.getSize(register).height, greaterThanOrEqualTo(48));

        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(fields[0].autofillHints, contains(AutofillHints.email));
        expect(fields[1].autofillHints, contains(AutofillHints.password));

        expect(find.byTooltip('Lihat password'), findsOneWidget);
        await tester.tap(find.byTooltip('Lihat password'));
        await tester.pump();
        expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Register', () {
    testWidgets('field kosong dan terms belum dicentang tampil inline', (
      tester,
    ) async {
      await _pumpRegister(tester);

      final terms = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(terms.value, isFalse);

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Password wajib diisi.'), findsOneWidget);
      expect(find.text('Konfirmasi password wajib diisi.'), findsOneWidget);
      expect(
        find.text('Setujui syarat & ketentuan untuk melanjutkan.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('nama pendek, email, password, dan konfirmasi ditolak inline', (
      tester,
    ) async {
      await _pumpRegister(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'A');
      await tester.enterText(find.byType(TextFormField).at(1), 'siti@');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.enterText(find.byType(TextFormField).at(3), '456');
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama minimal 2 karakter.'), findsOneWidget);
      expect(find.text('Format email tidak valid.'), findsOneWidget);
      expect(find.text('Password minimal 8 karakter.'), findsOneWidget);
      expect(find.text('Konfirmasi password belum sama.'), findsOneWidget);
    });

    testWidgets('terms belum dicentang menghalangi submit secara inline', (
      tester,
    ) async {
      await _pumpRegister(tester);
      await _fillRegister(tester);

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(
        find.text('Setujui syarat & ketentuan untuk melanjutkan.'),
        findsOneWidget,
      );
      expect(find.byType(FormErrorBanner), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('error server tampil di banner, bukan SnackBar', (
      tester,
    ) async {
      await _pumpRegister(tester, auth: _FailingAuth());
      await _fillRegister(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.byType(FormErrorBanner), findsOneWidget);
      expect(find.text('Email sudah terdaftar.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('field punya autofill hint dan toggle password dinamis', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpRegister(tester);

        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(fields[0].autofillHints, contains(AutofillHints.name));
        expect(fields[1].autofillHints, contains(AutofillHints.email));
        expect(fields[2].autofillHints, contains(AutofillHints.newPassword));
        expect(fields[3].autofillHints, contains(AutofillHints.newPassword));

        expect(find.byTooltip('Lihat password'), findsOneWidget);
        await tester.tap(find.byTooltip('Lihat password'));
        await tester.pump();
        expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });
}
