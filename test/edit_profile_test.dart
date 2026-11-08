import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/screens/profile/edit_profile_screen.dart';
import 'package:eventkuy/services/avatar_service.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({super.initialUser});

  String? updateResult;
  int updateCalls = 0;
  String? savedName;
  String? savedAvatarUrl;

  @override
  Future<String?> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    updateCalls += 1;
    savedName = name;
    savedAvatarUrl = avatarUrl;
    return updateResult;
  }
}

Widget _app(AuthProvider auth, {AvatarImagePicker? pickImage}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(pickImage: pickImage),
                ),
              ),
              child: const Text('Buka Edit Profil'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  AuthProvider auth, {
  AvatarImagePicker? pickImage,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(auth, pickImage: pickImage));
  await tester.tap(find.text('Buka Edit Profil'));
  await tester.pumpAndSettle();
}

Future<void> _pickFromGallery(WidgetTester tester) async {
  await tester.tap(find.text('Ganti Foto'));
  await tester.pumpAndSettle();
  if (find.text('Pilih dari Galeri').evaluate().isNotEmpty) {
    await tester.tap(find.text('Pilih dari Galeri'));
    await tester.pumpAndSettle();
  }
}

void main() {
  const user = AppUser(id: 'u1', name: 'Siti Rahma', email: 'siti@example.com');

  testWidgets('field nama terisi nama saat ini dan email read-only', (
    tester,
  ) async {
    await _open(tester, _FakeAuthProvider(initialUser: user));

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('edit-profile-name')),
    );
    expect(field.controller?.text, 'Siti Rahma');
    expect(field.readOnly, isFalse);
    expect(find.text('siti@example.com'), findsOneWidget);
  });

  testWidgets('nama kosong ditolak tanpa memanggil updateProfile', (
    tester,
  ) async {
    final auth = _FakeAuthProvider(initialUser: user);
    await _open(tester, auth);

    await tester.enterText(find.byKey(const ValueKey('edit-profile-name')), '');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Nama wajib diisi.'), findsOneWidget);
    expect(auth.updateCalls, 0);
  });

  testWidgets('nama 1 karakter ditolak', (tester) async {
    final auth = _FakeAuthProvider(initialUser: user);
    await _open(tester, auth);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'A',
    );
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Nama minimal 2 karakter.'), findsOneWidget);
    expect(auth.updateCalls, 0);
  });

  testWidgets('simpan sukses mengirim nama yang di-trim dan menutup layar', (
    tester,
  ) async {
    final auth = _FakeAuthProvider(initialUser: user);
    await _open(tester, auth);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      '  Siti Baru  ',
    );
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(auth.updateCalls, 1);
    expect(auth.savedName, 'Siti Baru');
    expect(find.text('Buka Edit Profil'), findsOneWidget);
    expect(find.text('Edit Profil'), findsNothing);
  });

  testWidgets('error dari provider ditampilkan dan layar tetap terbuka', (
    tester,
  ) async {
    final auth = _FakeAuthProvider(initialUser: user)
      ..updateResult = 'Gagal menyimpan profil.';
    await _open(tester, auth);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Siti Baru',
    );
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Gagal menyimpan profil.'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });

  testWidgets('field nama punya label yang terbaca pembaca layar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester, _FakeAuthProvider(initialUser: user));

      final node = tester.getSemantics(
        find.byKey(const ValueKey('edit-profile-name')),
      );
      expect(node.label, contains('Nama Lengkap'));
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('nama kosong memakai error inline dan fokus ke field', (
    tester,
  ) async {
    final auth = _FakeAuthProvider(initialUser: user);
    await _open(tester, auth);

    await tester.enterText(find.byKey(const ValueKey('edit-profile-name')), '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('edit-profile-name')),
    );
    expect(field.decoration?.errorText, 'Nama wajib diisi.');
    expect(field.focusNode?.hasFocus, isTrue);
    expect(find.byType(SnackBar), findsNothing);
    expect(auth.updateCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Siti Baru',
    );
    await tester.pump();
    expect(find.text('Nama wajib diisi.'), findsNothing);
  });

  testWidgets('error provider tampil inline tanpa SnackBar', (tester) async {
    final auth = _FakeAuthProvider(initialUser: user)
      ..updateResult = 'Gagal menyimpan profil.';
    await _open(tester, auth);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Siti Baru',
    );
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Gagal menyimpan profil.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('edit-profile-name')))
          .decoration
          ?.errorText,
      isNull,
    );
  });

  testWidgets('avatar dan tombol ganti foto punya target minimal 48', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester, _FakeAuthProvider(initialUser: user));

      final avatar = find.bySemanticsLabel('Ganti foto profil');
      expect(avatar, findsOneWidget);
      expect(tester.getSize(avatar).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(avatar).height, greaterThanOrEqualTo(48));

      final changePhoto = find.widgetWithText(OutlinedButton, 'Ganti Foto');
      expect(changePhoto, findsOneWidget);
      expect(tester.getSize(changePhoto).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('avatar kosong memakai inisial nama', (tester) async {
    await _open(tester, _FakeAuthProvider(initialUser: user));

    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('pilih GIF ditolak dan tidak menjadi pratinjau', (tester) async {
    final gif = Uint8List.fromList([
      ...'GIF89a'.codeUnits,
      0x01,
      0x00,
      0x01,
      0x00,
    ]);

    await _open(
      tester,
      _FakeAuthProvider(initialUser: user),
      pickImage: (_) async =>
          XFile.fromData(gif, name: 'foto.gif', mimeType: 'image/gif'),
    );

    await _pickFromGallery(tester);

    expect(find.text(AvatarService.formatErrorMessage), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('pilih PNG diterima dan tampil sebagai pratinjau', (
    tester,
  ) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await _open(
      tester,
      _FakeAuthProvider(initialUser: user),
      pickImage: (_) async =>
          XFile.fromData(png, name: 'foto.png', mimeType: 'image/png'),
    );

    await _pickFromGallery(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(AvatarService.formatErrorMessage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
