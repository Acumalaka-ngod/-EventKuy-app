import 'package:supabase_flutter/supabase_flutter.dart';

/// Pesan error yang ramah untuk ditampilkan ke pengguna.
///
/// Detail mentah dari server tidak pernah diteruskan langsung ke UI karena
/// bisa membocorkan struktur database (nama constraint, hint, detail SQL).
/// Pengecualian hanya untuk pesan bisnis yang memang dibuat oleh RPC kita
/// sendiri (kode `P0001`), misalnya "Stok tiket habis.".
String friendlyError(Object error) {
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _postgrestMessage(error);
  if (error is StateError) return error.message;
  return 'Terjadi kesalahan. Periksa koneksi internet lalu coba lagi.';
}

String _authMessage(AuthException error) {
  switch (error.code) {
    case 'invalid_credentials':
      return 'Email atau password salah.';
    case 'email_not_confirmed':
      return 'Email belum dikonfirmasi. Buka tautan verifikasi di inbox lalu coba lagi.';
    case 'user_already_exists':
    case 'email_exists':
      return 'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
    case 'weak_password':
      return 'Password terlalu lemah. Gunakan minimal 8 karakter.';
    case 'same_password':
      return 'Password baru harus berbeda dari password lama.';
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    case 'otp_expired':
      return 'Kode verifikasi sudah kedaluwarsa. Minta kode baru.';
    case 'session_not_found':
    case 'refresh_token_not_found':
      return 'Sesi sudah berakhir. Silakan masuk lagi.';
    case 'signup_disabled':
      return 'Pendaftaran sedang ditutup.';
    case 'provider_disabled':
      return 'Metode login ini sedang tidak tersedia.';
    default:
      return 'Autentikasi gagal. Periksa data lalu coba lagi.';
  }
}

String _postgrestMessage(PostgrestException error) {
  switch (error.code) {
    // Pesan bisnis dari RPC milik kita (stok habis, voucher dipakai, dll).
    case 'P0001':
      return error.message.isEmpty
          ? 'Permintaan tidak dapat diproses.'
          : error.message;
    case 'PGRST116':
      return 'Data tidak ditemukan.';
    case '42501':
      return 'Kamu tidak punya akses untuk tindakan ini.';
    case '23505':
      return 'Data sudah ada.';
    case '23503':
      return 'Data terkait tidak ditemukan.';
    case '23514':
      return 'Data yang dikirim tidak valid.';
    default:
      return 'Terjadi kesalahan pada server. Coba lagi.';
  }
}
