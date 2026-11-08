import 'package:flutter/widgets.dart';

/// Kebijakan gerak aplikasi.
///
/// EventKuy mengikuti pengaturan aksesibilitas sistem
/// (`MediaQueryData.disableAnimations`). Saat reduced motion aktif, durasi
/// animasi dekoratif menjadi nol; animasi fungsional tetap boleh berjalan
/// dengan durasi minimal bila diperlukan.
class AppMotion {
  AppMotion._();

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Durasi normal, atau nol saat reduced motion aktif.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}
