import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Mark EventKuy — kotak gradien dengan tiga bar equalizer putih.
/// Dipakai di splash, header beranda, tiket, dan sidebar.
class EventKuyMark extends StatelessWidget {
  final double size;
  final bool onDark;

  const EventKuyMark({super.key, this.size = 32, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final radius = size * (10 / 34);
    final padding = size * (7 / 34);
    final barWidth = size * (5 / 34);
    final barHeights = [
      size * (11 / 34),
      size * (20 / 34),
      size * (15 / 34),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: -3 * math.pi / 180,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: onDark
                ? Colors.white.withValues(alpha: 0.16)
                : AppTheme.violet,
            border: onDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final height in barHeights)
                Container(
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(barWidth),
                      bottom: Radius.circular(barWidth * 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo lengkap: mark + wordmark "EVENTKUY" (opsional).
class EventKuyLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool onDark;
  final bool withWordmark;

  const EventKuyLogo({
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
        EventKuyMark(size: markSize, onDark: onDark),
        if (withWordmark) ...[
          SizedBox(width: markSize * 0.32),
          Text(
            'EVENTKUY',
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -fontSize * 0.04,
              height: 1.0,
              color: onDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ],
      ],
    );
  }
}
