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

String formatBulanPendek(DateTime d) {
  try {
    return DateFormat('MMM', 'id_ID').format(d).toUpperCase();
  } catch (_) {
    return DateFormat('MMM').format(d).toUpperCase();
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

/// Tombol hati bulat putih di pojok foto.
class _FavoriteButton extends StatelessWidget {
  final Event event;
  final double size;

  const _FavoriteButton({required this.event, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final isFav = fav.isFav(event.id);

    return GestureDetector(
      onTap: () => fav.toggle(event.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size * 0.48,
          color: isFav ? AppTheme.coral : AppTheme.ink,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.violetDark,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

/// Kartu list horizontal (Jelajahi & Favorit di layar sempit).
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 138,
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EventImage(
                        imageUrl: event.imageUrl,
                        eventId: event.id,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _CategoryBadge(category: event.category),
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: _FavoriteButton(event: event, size: 32),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatTanggalSingkat(event.date).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                            color: AppTheme.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: AppTheme.coral),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${cityOf(event.location)} · ${venueOf(event.location)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                formatRp(event.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.violetDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              '/orang',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu grid untuk Beranda, Jelajahi, dan Favorit.
class EventGridCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventGridCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                    ),
                    Positioned(
                      top: 11,
                      left: 11,
                      child: _CategoryBadge(category: event.category),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _FavoriteButton(event: event),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTanggalSingkat(event.date).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.35,
                        color: AppTheme.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppTheme.coral),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${cityOf(event.location)} · ${venueOf(event.location)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            formatRp(event.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.violetDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '/orang',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 9.5,
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
