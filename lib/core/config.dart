// Konfigurasi global AjangIn.
// Ganti baseUrl saat backend Laravel production sudah online (wajib HTTPS).
class AppConfig {
  static const String appName = 'AjangIn';
  static const String applicationId = 'com.ajangin.app';

  // TODO Fase 2: isi dengan URL VPS Laravel, contoh https://api.ajangin.id
  static const String apiBaseUrl = 'https://api.ajangin.id/api';
  static const Duration apiTimeout = Duration(seconds: 15);

  // Catatan: lokasi event ditampilkan sebagai teks alamat lengkap (tanpa peta/Google Maps API).

  // TODO Fase 5: isi Midtrans client key (Sandbox dulu, lalu Production)
  static const String midtransClientKey = '';
  static const bool midtransIsProduction = false;
}
