import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/formatters.dart';
import 'package:eventkuy/core/theme.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/models/user.dart';
import 'package:eventkuy/providers/auth_provider.dart';
import 'package:eventkuy/providers/event_provider.dart';
import 'package:eventkuy/screens/organizer/organizer_event_editor_screen.dart';
import 'package:eventkuy/services/event_image_service.dart';
import 'package:eventkuy/services/mock_api_service.dart';

const _user = AppUser(
  id: 'org-1',
  name: 'Organizer Demo',
  email: 'organizer@example.com',
  role: 'organizer',
);

/// PNG 1x1 valid agar Image.memory bisa mendekode preview di widget test.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

final Uint8List _gifBytes = Uint8List.fromList([
  ...'GIF89a'.codeUnits,
  0x01,
  0x00,
  0x01,
  0x00,
]);

class _FakeUploader implements EventImageUploader {
  int uploadCalls = 0;
  int deleteCalls = 0;
  final String url =
      'https://abc.supabase.co/storage/v1/object/public/event-images/'
      'org-1/poster.png';

  @override
  Future<String> uploadEventImage({
    required String userId,
    String? eventId,
    required Uint8List bytes,
    String? extension,
    String? contentType,
  }) async {
    uploadCalls += 1;
    return url;
  }

  @override
  Future<void> deleteImage(String url) async {
    deleteCalls += 1;
  }
}

Widget _app({
  required EventProvider events,
  Event? event,
  EventImageUploader? imageService,
  EventImagePicker? pickImage,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(initialUser: _user),
      ),
      ChangeNotifierProvider<EventProvider>.value(value: events),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: _Launcher(
        event: event,
        imageService: imageService,
        pickImage: pickImage,
      ),
    ),
  );
}

class _Launcher extends StatelessWidget {
  const _Launcher({this.event, this.imageService, this.pickImage});

  final Event? event;
  final EventImageUploader? imageService;
  final EventImagePicker? pickImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => OrganizerEventEditorScreen(
                  event: event,
                  imageService: imageService,
                  pickImage: pickImage,
                ),
              ),
            );
          },
          child: const Text('Buka Editor'),
        ),
      ),
    );
  }
}

Future<EventProvider> _loadedProvider(
  WidgetTester tester,
  MockApiService api,
) async {
  final provider = EventProvider(api: api);
  await tester.runAsync(() async {
    await provider.loadEvents();
  });
  return provider;
}

Future<void> _open(
  WidgetTester tester, {
  required EventProvider events,
  Event? event,
  EventImageUploader? imageService,
  EventImagePicker? pickImage,
  Size size = const Size(390, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(
      events: events,
      event: event,
      imageService: imageService,
      pickImage: pickImage,
    ),
  );
  await tester.tap(find.text('Buka Editor'));
  await tester.pumpAndSettle();
}

TextField _field(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(ValueKey(key)));
}

Future<void> _fillCreateForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('event-editor-title')),
    'Konser Kampus',
  );
  await tester.enterText(
    find.byKey(const ValueKey('event-editor-description')),
    'Konser musik mahasiswa dengan bintang tamu lokal.',
  );
  await tester.enterText(
    find.byKey(const ValueKey('event-editor-location')),
    'Auditorium Kampus, Bandung',
  );
  await tester.enterText(
    find.byKey(const ValueKey('event-editor-price')),
    '75000',
  );
  await tester.enterText(
    find.byKey(const ValueKey('event-editor-quota')),
    '500',
  );
}

Future<void> _pickPosterFromGallery(WidgetTester tester) async {
  await tester.tap(find.text('Pilih Poster'));
  await tester.pumpAndSettle();
  if (find.text('Pilih dari Galeri').evaluate().isNotEmpty) {
    await tester.tap(find.text('Pilih dari Galeri'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('mode buat menampilkan form kosong', (tester) async {
    final api = MockApiService(organizerId: _user.id);
    final events = await _loadedProvider(tester, api);

    await _open(tester, events: events);

    expect(find.text('Buat Event Baru'), findsOneWidget);
    expect(find.text('Buat Event'), findsOneWidget);
    expect(_field(tester, 'event-editor-title').controller?.text, isEmpty);
    expect(_field(tester, 'event-editor-price').controller?.text, isEmpty);
  });

  testWidgets('form editor muat di layar 390x844 tanpa overflow', (
    tester,
  ) async {
    final api = MockApiService(organizerId: _user.id);
    final events = await _loadedProvider(tester, api);

    await _open(tester, events: events, size: const Size(390, 844));
    expect(find.text('Buat Event Baru'), findsOneWidget);

    // Gulir bertahap sampai bawah form. RenderFlex overflow akan tercatat
    // sebagai exception layout dan menggagalkan test ini.
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(find.text('Buat Event'), findsOneWidget);
  });

  testWidgets('form kosong ditolak tanpa menyimpan event', (tester) async {
    final api = MockApiService(organizerId: _user.id);
    final events = await _loadedProvider(tester, api);
    final before = events.events.length;

    await _open(tester, events: events);
    await tester.tap(find.byKey(const ValueKey('event-editor-save')));
    await tester.pump();

    expect(find.text('Nama event wajib diisi.'), findsOneWidget);
    expect(find.text('Deskripsi event wajib diisi.'), findsOneWidget);
    expect(find.text('Lokasi event wajib diisi.'), findsOneWidget);
    expect(find.text('Harga tiket wajib diisi.'), findsOneWidget);
    expect(find.text('Kuota tiket wajib diisi.'), findsOneWidget);
    expect(events.events.length, before);
  });

  testWidgets('mode edit mengisi form dengan data event', (tester) async {
    final api = MockApiService();
    final events = await _loadedProvider(tester, api);
    final event = events.events.first;

    await _open(tester, events: events, event: event);

    expect(find.text('Edit Event'), findsOneWidget);
    expect(_field(tester, 'event-editor-title').controller?.text, event.title);
    expect(
      _field(tester, 'event-editor-description').controller?.text,
      event.description,
    );
    expect(
      _field(tester, 'event-editor-location').controller?.text,
      event.location,
    );
    expect(
      _field(tester, 'event-editor-price').controller?.text,
      '${event.price}',
    );
    expect(
      _field(tester, 'event-editor-quota').controller?.text,
      '${event.quota}',
    );
    expect(find.text(formatTanggal(event.date)), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
  });

  testWidgets('menyimpan perubahan memperbarui data event', (tester) async {
    final api = MockApiService();
    final events = await _loadedProvider(tester, api);
    final event = events.events.first;

    await _open(tester, events: events, event: event);
    await tester.enterText(
      find.byKey(const ValueKey('event-editor-title')),
      'Judul Hasil Edit',
    );
    await tester.tap(find.byKey(const ValueKey('event-editor-save')));
    await tester.pumpAndSettle();

    expect(events.eventById(event.id)?.title, 'Judul Hasil Edit');
    expect(find.text('Buka Editor'), findsOneWidget);
  });

  testWidgets('poster yang dipilih diunggah saat event disimpan', (
    tester,
  ) async {
    final api = MockApiService(organizerId: _user.id);
    final events = await _loadedProvider(tester, api);
    final uploader = _FakeUploader();

    await _open(
      tester,
      events: events,
      imageService: uploader,
      pickImage: (_) async => XFile.fromData(
        _pngBytes,
        name: 'poster.png',
        mimeType: 'image/png',
      ),
    );
    await _fillCreateForm(tester);

    await _pickPosterFromGallery(tester);
    expect(find.text('Ganti Poster'), findsOneWidget);
    expect(uploader.uploadCalls, 0);

    await tester.tap(find.byKey(const ValueKey('event-editor-save')));
    await tester.pumpAndSettle();

    expect(uploader.uploadCalls, 1);
    final created = events.events.firstWhere(
      (event) => event.title == 'Konser Kampus',
    );
    expect(created.imageUrl, uploader.url);
  });

  testWidgets('GIF ditolak sebelum diunggah', (tester) async {
    final api = MockApiService(organizerId: _user.id);
    final events = await _loadedProvider(tester, api);
    final uploader = _FakeUploader();

    await _open(
      tester,
      events: events,
      imageService: uploader,
      pickImage: (_) async => XFile.fromData(
        _gifBytes,
        name: 'anim.gif',
        mimeType: 'image/gif',
      ),
    );

    await _pickPosterFromGallery(tester);

    expect(
      find.text(EventImageService.formatErrorMessage),
      findsOneWidget,
    );
    expect(find.text('Pilih Poster'), findsOneWidget);
    expect(uploader.uploadCalls, 0);
  });

  testWidgets('menghapus poster mengosongkan image_url saat disimpan', (
    tester,
  ) async {
    final api = MockApiService();
    final events = await _loadedProvider(tester, api);
    final event = events.events.first;
    final uploader = _FakeUploader();

    await _open(
      tester,
      events: events,
      event: event,
      imageService: uploader,
    );
    await tester.tap(find.text('Hapus'));
    await tester.pump();
    expect(find.text('Pilih Poster'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-editor-save')));
    await tester.pumpAndSettle();

    expect(events.eventById(event.id)?.imageUrl, isEmpty);
    expect(uploader.deleteCalls, 1);
  });
}
