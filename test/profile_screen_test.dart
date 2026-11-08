import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/providers/ticket_provider.dart';
import 'package:eventkuy/screens/profile/profile_screen.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _user = AppUser(
  id: 'u1',
  name: 'Siti Rahma',
  email: 'siti@example.com',
);

const _organizer = AppUser(
  id: 'u2',
  name: 'Organizer Demo',
  email: 'organizer@example.com',
  role: 'organizer',
);

Widget _app({
  required AuthProvider auth,
  required TicketProvider tickets,
  required FavoriteProvider favorites,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<TicketProvider>.value(value: tickets),
      ChangeNotifierProvider<FavoriteProvider>.value(value: favorites),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const ProfileScreen(),
    ),
  );
}

void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<({TicketProvider tickets, FavoriteProvider favorites})> _seed(
  WidgetTester tester,
  MockApiService api, {
  bool checkout = false,
  bool checkIn = false,
  bool favorite = false,
}) async {
  final tickets = TicketProvider(api: api, pollInterval: null);
  final favorites = FavoriteProvider(api: api);

  await tester.runAsync(() async {
    final event = (await api.fetchEvents()).first;
    if (checkout) {
      final result = await tickets.checkout(event);
      if (checkIn) await tickets.checkIn(result.ticket.code);
    }
    if (favorite) {
      await api.addFavorite(event.id);
      await favorites.load();
    }
  });

  return (tickets: tickets, favorites: favorites);
}

void main() {
  testWidgets('statistik memakai angka nyata dari provider', (tester) async {
    _tallSurface(tester);
    final api = MockApiService();
    final seeded = await _seed(
      tester,
      api,
      checkout: true,
      checkIn: true,
      favorite: true,
    );

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Siti Rahma'), findsOneWidget);
    expect(find.text('siti@example.com'), findsOneWidget);
    expect(find.text('Tiket Saya'), findsOneWidget);
    expect(find.text('Favorit'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);
    // Tiket, favorit, dan check-in masing-masing bernilai 1.
    expect(find.text('1'), findsNWidgets(3));
    expect(find.text('Poin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistik nol saat belum ada aktivitas', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('badge pengguna biasa adalah Member EventKuy', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member EventKuy'), findsOneWidget);
    expect(find.text('Organizer EventKuy'), findsNothing);
    expect(find.text('MODE ORGANIZER'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('badge organizer dan menu organizer tampil untuk role organizer', (
    tester,
  ) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _organizer),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Organizer EventKuy'), findsOneWidget);
    expect(find.text('Member EventKuy'), findsNothing);
    expect(find.text('MODE ORGANIZER'), findsOneWidget);
    expect(find.text('Dashboard Organizer'), findsOneWidget);
    expect(find.text('Scan QR Check-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar kosong memakai inisial nama', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gear membuka Pengaturan dengan 4 menu', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Pusat Bantuan & FAQ'), findsOneWidget);
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol pengaturan dan avatar punya label serta target 48', (
    tester,
  ) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          auth: AuthProvider(initialUser: _user),
          tickets: seeded.tickets,
          favorites: seeded.favorites,
        ),
      );
      await tester.pumpAndSettle();

      final settings = find.bySemanticsLabel('Buka pengaturan');
      expect(settings, findsOneWidget);
      expect(tester.getSize(settings).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(settings).height, greaterThanOrEqualTo(48));

      final avatar = find.bySemanticsLabel('Ganti foto profil');
      expect(avatar, findsOneWidget);
      expect(tester.getSize(avatar).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(avatar).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('menu Edit Informasi Profil membuka layar edit', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Informasi Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu Riwayat Transaksi membuka layar riwayat', (tester) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat Transaksi'));
    await tester.pumpAndSettle();

    // Tanpa konfigurasi Supabase, layar tetap terbuka dengan state gagal.
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Gagal memuat riwayat transaksi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu Hubungi CS dan Metode Pembayaran sudah dihapus', (
    tester,
  ) async {
    _tallSurface(tester);
    final seeded = await _seed(tester, MockApiService());

    await tester.pumpWidget(
      _app(
        auth: AuthProvider(initialUser: _user),
        tickets: seeded.tickets,
        favorites: seeded.favorites,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metode Pembayaran'), findsNothing);
    expect(find.text('Hubungi CS'), findsNothing);
    expect(find.text('Keluar dari Akun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
