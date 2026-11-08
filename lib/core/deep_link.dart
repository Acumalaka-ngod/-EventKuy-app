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

  /// Buat tautan event untuk custom scheme, contoh:
  /// `eventkuy://event/11111111-...`.
  static String eventUri(String eventId) => '$scheme://event/$eventId';

  /// Ambil ID event dari tautan deep link. Mengembalikan null bila
  /// tautan tidak sesuai format eventkuy://event/id atau /#/event/id.
  static String? eventIdFromUri(String? uri) {
    if (uri == null || uri.isEmpty) return null;

    // Custom scheme: eventkuy://event/<id>
    final schemePrefix = '$scheme://event/';
    if (uri.startsWith(schemePrefix)) {
      return uri.substring(schemePrefix.length);
    }

    // Web hash: https://<host>/#/event/<id>
    final hashPrefix = '#/event/';
    final hashIndex = uri.indexOf(hashPrefix);
    if (hashIndex >= 0) {
      final afterHash = uri.substring(hashIndex + hashPrefix.length);
      final id = afterHash.split('?').first.split('#').first;
      if (id.isNotEmpty) return id;
    }

    // Web path (fallback tanpa hash): /event/<id>
    final pathPrefix = '/event/';
    final pathIndex = uri.indexOf(pathPrefix);
    if (pathIndex >= 0) {
      final afterPath = uri.substring(pathIndex + pathPrefix.length);
      final id = afterPath.split('?').first.split('#').first.split('/').first;
      if (id.isNotEmpty) return id;
    }

    return null;
  }

  /// Validasi apakah URI adalah deep link event EventKuy.
  static bool isEventLink(String? uri) => eventIdFromUri(uri) != null;
}
