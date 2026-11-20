import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/config.dart';

/// Hasil percobaan masuk dengan Google.
class GoogleAuthResult {
  const GoogleAuthResult.success(String this.idToken)
    : error = null,
      canceled = false;

  const GoogleAuthResult.canceled()
    : idToken = null,
      error = null,
      canceled = true;

  const GoogleAuthResult.failure(String this.error)
    : idToken = null,
      canceled = false;

  /// ID token yang ditukar ke Supabase lewat `signInWithIdToken`.
  final String? idToken;
  final String? error;
  final bool canceled;
}

/// Google Sign-In native (Android) memakai `google_sign_in` 7.x.
///
/// Alurnya: tampilkan pemilih akun Google, ambil ID token, lalu tukar token
/// tersebut menjadi sesi Supabase di [AuthProvider].
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  /// Native sign-in baru dikonfigurasi untuk Android. Platform lain belum
  /// memiliki OAuth client sendiri, jadi tombolnya diberi pesan yang jelas.
  bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<GoogleAuthResult> signIn() async {
    if (!isAvailable) {
      return const GoogleAuthResult.failure(
        'Masuk dengan Google saat ini hanya tersedia di aplikasi Android.',
      );
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleAuthResult.failure(
          'Google tidak mengembalikan token masuk. Coba lagi.',
        );
      }
      return GoogleAuthResult.success(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleAuthResult.canceled();
      }
      debugPrint('Google Sign-In gagal: ${error.code} — ${error.description}');
      return const GoogleAuthResult.failure(
        'Gagal masuk dengan Google. Coba lagi.',
      );
    } catch (error) {
      debugPrint('Google Sign-In gagal: $error');
      return const GoogleAuthResult.failure(
        'Gagal masuk dengan Google. Coba lagi.',
      );
    }
  }

  /// `initialize` wajib dipanggil tepat sekali sebelum method lain.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleWebClientId,
    );
    _initialized = true;
  }

  /// Putuskan sesi Google agar pemilih akun muncul lagi pada login berikutnya.
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      debugPrint('Gagal keluar dari sesi Google: $error');
    }
  }
}
