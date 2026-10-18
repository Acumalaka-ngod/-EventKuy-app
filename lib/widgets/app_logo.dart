import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Mark AjangIn — huruf "A" geometris dua warna (facet indigo & indigo muda).
/// Dipakai di splash, header beranda, tiket, dan sidebar.
class AjanginMark extends StatelessWidget {
  final double size;
  final bool onDark;

  const AjanginMark({super.key, this.size = 32, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(onDark: onDark),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final bool onDark;

  _MarkPainter({required this.onDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final darkColor =
        onDark ? Colors.white : AppTheme.primary;
    final lightColor = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF818CF8);

    Path p(double x, double y) => Path()..moveTo(x * s, y * s);

    // Kaki kiri (indigo tua)
    final left = p(50, 4)
      ..lineTo(12, 96)
      ..lineTo(33, 96)
      ..lineTo(50, 46)
      ..close();
    canvas.drawPath(left, Paint()..color = darkColor);

    // Kaki kanan (indigo muda — efek lipatan)
    final right = p(50, 4)
      ..lineTo(88, 96)
      ..lineTo(67, 96)
      ..lineTo(50, 46)
      ..close();
    canvas.drawPath(right, Paint()..color = lightColor);

    // Palang A
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(35 * s, 72 * s, 30 * s, 11 * s),
      Radius.circular(3 * s),
    );
    canvas.drawRRect(bar, Paint()..color = darkColor);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}

/// Logo lengkap: mark + wordmark "AJANGIN" (opsional).
class AjanginLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool onDark;
  final bool withWordmark;

  const AjanginLogo({
    super.key,
    this.markSize = 30,
    this.fontSize = 17,
    this.onDark = false,
    this.withWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AjanginMark(size: markSize, onDark: onDark),
        if (withWordmark) ...[
          SizedBox(width: markSize * 0.45),
          Text(
            'AJANGIN',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              height: 1.0,
              color: onDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ],
      ],
    );
  }
}
