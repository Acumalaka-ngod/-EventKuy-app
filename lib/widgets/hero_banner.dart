import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/event.dart';
import 'event_card.dart';
import 'event_image.dart';

/// Hero Beranda: poster di satu bidang, keterangan event di bidang lain.
///
/// Sebelumnya judul event ditumpuk di atas poster. Poster demo sudah memuat
/// judulnya sendiri, jadi judul tampil dua kali, dan chip "FEATURED EVENT"
/// menabrak label kategori. Sekarang poster dan teks tidak lagi berbagi ruang.
class HeroBanner extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final double height;

  const HeroBanner({
    super.key,
    required this.event,
    required this.onTap,
    this.height = 330,
  });

  @override
  Widget build(BuildContext context) {
    final kicker =
        '${event.category.toUpperCase()}  ·  ${formatTanggalSingkat(event.date)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final titleSize = wide ? 28.0 : 24.0;

        final info = Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 24 : 16,
            wide ? 24 : 14,
            wide ? 24 : 16,
            wide ? 24 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kicker,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  color: AppTheme.violetDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.headingFont,
                  color: AppTheme.ink,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                venueOf(event.location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  color: AppTheme.muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        );

        final poster = EventImage(
          imageUrl: event.imageUrl,
          eventId: event.id,
          fit: BoxFit.cover,
        );

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusHero),
              border: Border.all(color: AppTheme.border),
            ),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: poster),
                      Expanded(flex: 2, child: info),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: poster),
                      info,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
