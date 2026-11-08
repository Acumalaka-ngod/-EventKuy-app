import 'organizer.dart';

/// Model Event — mirror tabel `public.events` di Supabase.
class Event {
  final String id;
  final String? organizerId;
  final String? organizerProfileId;

  /// Profil penyelenggara (diisi saat fetch events dengan join organizers).
  final Organizer? organizer;

  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int price;
  final int quota;

  /// Jumlah tiket yang sudah terjual (dihitung server lewat view `event_stock`).
  final int sold;
  final String imageUrl;
  final List<String> imageUrls;
  final String category;
  final List<String> tags;
  final String timeRange;

  /// Rating rata-rata event (0–5), read-only dari seed/backend.
  final double rating;

  /// Jumlah ulasan yang mendasari rating, read-only dari seed/backend.
  final int ratingCount;

  const Event({
    required this.id,
    this.organizerId,
    this.organizerProfileId,
    this.organizer,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.price,
    required this.quota,
    this.sold = 0,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.category,
    this.tags = const [],
    this.timeRange = '',
    this.rating = 0,
    this.ratingCount = 0,
  });

  /// Daftar foto untuk galeri detail event.
  /// Gambar utama ([imageUrl]) selalu di depan, duplikat & entri kosong dibuang.
  List<String> get galleryImages {
    final seen = <String>{};
    final result = <String>[];
    for (final url in [imageUrl, ...imageUrls]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      result.add(trimmed);
    }
    return List.unmodifiable(result);
  }

  /// Sisa tiket. `null` berarti kuota tidak dibatasi.
  int? get available {
    if (quota <= 0) return null;
    final sisa = quota - sold;
    return sisa < 0 ? 0 : sisa;
  }

  /// Tiket habis terjual (kuota terbatas dan sisa 0).
  bool get isSoldOut => available == 0;

  /// Salinan event dengan jumlah terjual yang sudah diperbarui.
  Event copyWith({
    int? sold,
    Organizer? organizer,
    double? rating,
    int? ratingCount,
  }) {
    return Event(
      id: id,
      organizerId: organizerId,
      organizerProfileId: organizerProfileId,
      organizer: organizer ?? this.organizer,
      title: title,
      description: description,
      date: date,
      location: location,
      price: price,
      quota: quota,
      sold: sold ?? this.sold,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      category: category,
      tags: tags,
      timeRange: timeRange,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      organizerId: json['organizer_id'] as String?,
      organizerProfileId: json['organizer_profile_id'] as String?,
      organizer: json['organizers'] != null
          ? Organizer.fromJson(Map<String, dynamic>.from(json['organizers']))
          : null,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      quota: (json['quota'] as num?)?.toInt() ?? 0,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      imageUrls: (json['image_urls'] as List?)
              ?.map((url) => url.toString())
              .toList(growable: false) ??
          const [],
      category: json['category'] as String? ?? 'Lainnya',
      tags: (json['tags'] as List?)
              ?.map((tag) => tag.toString())
              .toList(growable: false) ??
          const [],
      timeRange: json['time_range'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizer_id': organizerId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'location': location,
        'price': price,
        'quota': quota,
        'sold': sold,
        'image_url': imageUrl,
        'image_urls': imageUrls,
        'category': category,
        'tags': tags,
        'time_range': timeRange,
        'rating': rating,
        'rating_count': ratingCount,
      };
}
