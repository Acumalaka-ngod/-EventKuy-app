import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/theme.dart';

/// Kontras WCAG 2.1 untuk teks normal harus >= 4.5:1.
double _luminance(Color color) {
  double linearize(double channel) {
    if (channel <= 0.04045) return channel / 12.92;
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

double _contrast(Color foreground, Color background) {
  final lighter = math.max(_luminance(foreground), _luminance(background));
  final darker = math.min(_luminance(foreground), _luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('textFaint memenuhi kontras AA di semua latar layar profil', () {
    for (final background in <Color>[
      Colors.white,
      AppTheme.canvas,
      AppTheme.fieldBg,
    ]) {
      expect(
        _contrast(AppTheme.textFaint, background),
        greaterThanOrEqualTo(4.5),
        reason: 'textFaint di latar $background',
      );
    }
  });

  test('amber memenuhi kontras AA di latar chip dan permukaan', () {
    expect(
      _contrast(AppTheme.amber, const Color(0xFFFBF0DC)),
      greaterThanOrEqualTo(4.5),
      reason: 'chip Menunggu',
    );
    expect(
      _contrast(AppTheme.amber, Colors.white),
      greaterThanOrEqualTo(4.5),
      reason: 'teks amber di permukaan putih',
    );
  });
}
