import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'event_image.dart';

/// Galeri foto event untuk hero detail.
///
/// - Swipe kiri/kanan antar foto (`PageView`).
/// - Counter dinamis `n / total` + indikator titik.
/// - Tap foto membuka tampilan penuh yang bisa di-zoom.
class EventGallery extends StatefulWidget {
  final List<String> images;
  final String eventId;

  const EventGallery({
    super.key,
    required this.images,
    required this.eventId,
  });

  @override
  State<EventGallery> createState() => _EventGalleryState();
}

class _EventGalleryState extends State<EventGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
          images: widget.images,
          eventId: widget.eventId,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return EventImage(
        imageUrl: '',
        eventId: widget.eventId,
        fit: BoxFit.cover,
      );
    }

    final multiple = widget.images.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openViewer(i),
            child: EventImage(
              imageUrl: widget.images[i],
              eventId: widget.eventId,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Scrim fungsional agar tombol & counter tetap terbaca di atas foto.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.heroGradient),
          ),
        ),
        if (multiple) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x6B0A0819),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tampilan foto penuh: latar hitam, swipe, pinch-zoom, dan tombol tutup.
class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final String eventId;
  final int initialIndex;

  const _FullscreenGallery({
    required this.images,
    required this.eventId,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.images.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: EventImage(
                  imageUrl: widget.images[i],
                  eventId: widget.eventId,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (multiple)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
