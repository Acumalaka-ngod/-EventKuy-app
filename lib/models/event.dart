/// Model Event — mirror tabel `events` di Laravel (Fase 1).
class Event {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int price;
  final int quota;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final String timeRange;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.price,
    required this.quota,
    required this.imageUrl,
    required this.category,
    this.tags = const [],
    this.timeRange = '',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      price: json['price'] as int,
      quota: json['quota'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? 'Lainnya',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      timeRange: json['time_range'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'location': location,
        'price': price,
        'quota': quota,
        'image_url': imageUrl,
        'category': category,
        'tags': tags,
        'time_range': timeRange,
      };
}
