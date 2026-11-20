import 'package:firebase_core/firebase_core.dart';

// Konfigurasi global EventKuy.
// Nilai Supabase diisi saat run/build, contoh:
// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//   --dart-define=SUPABASE_ANON_KEY=eyJ...
class AppConfig {
  static const String appName = 'EventKuy';
  static const String applicationId = 'com.eventkuy.app';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── Firebase ──────────────────────────────────────────────────────
  // Android memakai android/app/google-services.json (tidak di-commit).
  // Platform lain (web/desktop) dapat memakai --dart-define FIREBASE_*.
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static bool get hasFirebaseDartConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  /// Opsi Firebase eksplisit. `null` berarti pakai konfigurasi native
  /// (`google-services.json` di Android).
  static FirebaseOptions? get firebaseOptions {
    if (!hasFirebaseDartConfig) return null;
    return FirebaseOptions(
      apiKey: firebaseApiKey,
      appId: firebaseAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
      storageBucket: firebaseStorageBucket.isEmpty
          ? null
          : firebaseStorageBucket,
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────
  // Client ID tipe "Web application" yang dipakai provider Google di
  // Supabase. Nilai ini harus sama dengan Client ID di dashboard Supabase
  // agar audience ID token cocok saat `signInWithIdToken`.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '833340557052-v7phvnlh4krdfejua06q05s997coohk9.apps.googleusercontent.com',
  );

  // Pembayaran Midtrans masih disimulasikan lewat RPC checkout.
  static const bool midtransIsProduction = false;
}
