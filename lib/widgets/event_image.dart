import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/mock_api_service.dart';

/// Gambar event yang tahan dua mode:
/// - kalau [imageUrl] diawali "assets/" -> coba Image.asset,
///   gagal (file belum ada) -> fallback network picsum.
/// - kalau URL -> CachedNetworkImage.
class EventImage extends StatelessWidget {
  final String imageUrl;
  final int eventId;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const EventImage({
    super.key,
    required this.imageUrl,
    required this.eventId,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl.startsWith('assets/')) {
      child = Image.asset(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _fallback(),
      );
    } else if (imageUrl.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (ctx, url) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (ctx, url, err) => _fallback(),
      );
    } else {
      child = _fallback();
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _fallback() {
    return CachedNetworkImage(
      imageUrl: MockApiService.fallbackUrl(eventId),
      height: height,
      width: width,
      fit: fit,
      placeholder: (ctx, url) => Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image)),
      ),
      errorWidget: (ctx, url, err) => Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 40),
      ),
    );
  }
}
