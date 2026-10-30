import 'package:supabase_flutter/supabase_flutter.dart';

/// Pesan error yang ramah untuk ditampilkan ke pengguna.
String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StateError) return error.message;
  return 'Terjadi kesalahan. Periksa koneksi internet lalu coba lagi.';
}
