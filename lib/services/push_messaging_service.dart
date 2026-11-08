/// Abstraksi layanan push messaging EventKuy.
///
/// Implementasi saat ini adalah no-op karena Firebase ditunda.
/// Saat kredensial Firebase tersedia, implemenasi FCM dapat ditambahkan
/// di sini tanpa mengubah kode yang memakai [PushMessagingService].
abstract class PushMessagingService {
  PushMessagingService._();

  /// Inisialisasi push messaging. Saat ini tidak melakukan apa-apa.
  Future<void> initialize() async {}

  /// Minta izin notifikasi dari user. Saat ini selalu mengembalikan false
  /// karena Firebase belum diaktifkan.
  Future<bool> requestPermission() async => false;

  /// Dapatkan token push perangkat. Saat ini mengembalikan null karena
  /// Firebase belum diaktifkan.
  Future<String?> getToken() async => null;

  /// Apakah push messaging tersedia (FCM aktif)?
  bool get isAvailable => false;
}

/// Implementasi no-op — dipakai saat Firebase belum dikonfigurasi.
class UnavailablePushMessagingService extends PushMessagingService {
  UnavailablePushMessagingService._() : super._();
  static final UnavailablePushMessagingService instance =
      UnavailablePushMessagingService._();
}
