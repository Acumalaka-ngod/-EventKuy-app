/// Parsing dan pembuatan tautan deep link EventKuy.
///
/// Format yang didukung:
/// - Custom scheme: eventkuy://event/id
/// - Web hash: https://host/#/event/id
class DeepLink {
  const DeepLink._();

  /// Skema kustom untuk aplikasi native.
  static const scheme = 'eventkuy';

  /// Path event di web hash.
  static const eventPath = '/event/';

  /// ID event harus UUID. Tautan dengan format lain diabaikan agar input
  /// dari luar tidak bisa memicu query dengan string sembarang.
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Buat tautan event untuk custom scheme, contoh:
  /// `eventkuy://event/11111111-...`.
  static String eventUri(String eventId) => '$scheme://event/$eventId';

  /// Ambil ID event dari tautan deep link. Mengembalikan null bila
  /// tautan tidak sesuai format eventkuy://event/id atau /#/event/id,
  /// atau bila ID bukan UUID yang valid.
  static String? eventIdFromUri(String? uri) {
    if (uri == null || uri.isEmpty) return null;

    // Custom scheme: eventkuy://event/<id>
    final schemePrefix = '$scheme://event/';
    if (uri.startsWith(schemePrefix)) {
      return _validId(uri.substring(schemePrefix.length));
    }

    // Web hash: https://<host>/#/event/<id>
    final hashPrefix = '#/event/';
    final hashIndex = uri.indexOf(hashPrefix);
    if (hashIndex >= 0) {
      return _validId(uri.substring(hashIndex + hashPrefix.length));
    }

    // Web path (fallback tanpa hash): /event/<id>
    final pathPrefix = '/event/';
    final pathIndex = uri.indexOf(pathPrefix);
    if (pathIndex >= 0) {
      return _validId(uri.substring(pathIndex + pathPrefix.length));
    }

    return null;
  }

  /// Ambil bagian ID, buang query/hash/trailing path, lalu validasi UUID.
  static String? _validId(String value) {
    final id = value.split('?').first.split('#').first.split('/').first;
    return _uuidPattern.hasMatch(id) ? id : null;
  }

  /// Validasi apakah URI adalah deep link event EventKuy.
  static bool isEventLink(String? uri) => eventIdFromUri(uri) != null;
}
