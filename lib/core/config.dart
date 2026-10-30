// Konfigurasi global EventKuy.
// Nilai Supabase diisi saat run/build, contoh:
// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//   --dart-define=SUPABASE_ANON_KEY=eyJ...
class AppConfig {
  static const String appName = 'EventKuy';
  static const String applicationId = 'com.eventkuy.app';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Pembayaran Midtrans masih disimulasikan lewat RPC checkout.
  static const bool midtransIsProduction = false;
}
