import 'event.dart';

/// Data yang dikirim organizer saat membuat atau mengubah event.
///
/// Dipisahkan dari [Event] karena form hanya boleh mengubah kolom yang
/// memang milik organizer. `id`, `organizer_id`, `sold`, dan rating diatur
/// oleh backend.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.price,
    required this.quota,
    required this.category,
    this.timeRange = '',
    this.imageUrl = '',
    this.imageUrls = const [],
    this.tags = const [],
  });

  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int price;
  final int quota;
  final String category;
  final String timeRange;
  final String imageUrl;
  final List<String> imageUrls;
  final List<String> tags;

  factory EventDraft.fromEvent(Event event) {
    return EventDraft(
      title: event.title,
      description: event.description,
      date: event.date,
      location: event.location,
      price: event.price,
      quota: event.quota,
      category: event.category,
      timeRange: event.timeRange,
      imageUrl: event.imageUrl,
      imageUrls: event.imageUrls,
      tags: event.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'date': dateOnly(date),
    'location': location.trim(),
    'price': price,
    'quota': quota,
    'category': category.trim(),
    'time_range': timeRange.trim(),
    'image_url': imageUrl.trim(),
    'image_urls': imageUrls,
    'tags': tags,
  };

  /// Kolom `events.date` bertipe `date`, jadi kirim tanpa komponen waktu.
  static String dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
