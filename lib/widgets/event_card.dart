import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/event.dart';
import '../providers/favorite_provider.dart';
import 'event_image.dart';

String formatRp(int v) => v == 0
    ? 'Gratis'
    : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(v);

/// Tanggal lengkap bahasa Indonesia, contoh: 12 Juli 2025
/// (fallback ke format Inggris bila data locale belum diinisialisasi,
/// misalnya saat widget test).
String formatTanggal(DateTime d) {
  try {
    return DateFormat('d MMMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return DateFormat('d MMMM yyyy').format(d);
  }
}

/// Tanggal pendek bahasa Indonesia, contoh: 12 Jul 2025
String formatTanggalSingkat(DateTime d) {
  try {
    return DateFormat('d MMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return DateFormat('d MMM yyyy').format(d);
  }
}

/// Warna aksen per kategori (untuk chip & badge).
Color categoryColor(String category) {
  switch (category) {
    case 'Workshop':
      return const Color(0xFFF97316);
    case 'Seminar':
      return const Color(0xFF0D9488);
    case 'Konser':
      return const Color(0xFF7C3AED);
    case 'Olahraga':
      return const Color(0xFF16A34A);
    default:
      return AppTheme.primary;
  }
}

String venueOf(String location) => location.split(',').first.trim();
String cityOf(String location) => location.split(',').last.trim();

/// Kartu list horizontal (Jelajahi & Favorit) sesuai desain baru.
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final isFav = fav.isFav(event.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Thumbnail + chip kategori
                Stack(
                  children: [
                    EventImage(
                      imageUrl: event.imageUrl,
                      eventId: event.id,
                      height: 84,
                      width: 84,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryColor(event.category),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Informasi event
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppTheme.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 11.5, color: AppTheme.textGrey),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${formatTanggal(event.date)} • ${cityOf(event.location)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        formatRp(event.price),
                        style: TextStyle(
                          color: event.price == 0
                              ? AppTheme.accentEmerald
                              : AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bookmark
                IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFav ? AppTheme.primary : AppTheme.textGrey,
                    size: 23,
                  ),
                  onPressed: () => fav.toggle(event.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu grid 2 kolom untuk Beranda & Favorit.
class EventGridCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventGridCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventImage(
                      imageUrl: event.imageUrl,
                      eventId: event.id,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13)),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: categoryColor(event.category),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppTheme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${formatTanggal(event.date)} • ${cityOf(event.location)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
