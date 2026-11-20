import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

/// Mendaftarkan lisensi DM Sans dan Manrope ke halaman licenses Flutter.
///
/// Teks lisensi dibundel sebagai aset sehingga satu sumber dipakai baik untuk
/// distribusi maupun tampilan `About -> Licenses`.
Future<void> registerFontLicenses() async {
  final license = await rootBundle.loadString('assets/fonts/OFL.txt');
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const ['Manrope', 'DM Sans'], license);
  });
}
