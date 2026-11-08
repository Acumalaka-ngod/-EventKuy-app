import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/theme.dart';

void main() {
  group('AppTheme tokens', () {
    test('radius terdefinisi dan positif', () {
      expect(AppTheme.radiusXs, greaterThan(0));
      expect(AppTheme.radiusSm, greaterThan(AppTheme.radiusXs));
      expect(AppTheme.radiusMd, greaterThan(AppTheme.radiusSm));
      expect(AppTheme.radiusLg, greaterThan(AppTheme.radiusMd));
      expect(AppTheme.radiusXl, greaterThan(AppTheme.radiusLg));
      expect(AppTheme.radius2xl, greaterThan(AppTheme.radiusXl));
      expect(AppTheme.radius3xl, greaterThan(AppTheme.radius2xl));
      expect(AppTheme.radiusPill, greaterThan(AppTheme.radius3xl));
    });

    test('alias lama masih merujuk ke token yang sama', () {
      expect(AppTheme.radiusButton, AppTheme.radiusSm);
      expect(AppTheme.radiusField, AppTheme.radiusSm);
      expect(AppTheme.radiusCard, AppTheme.radiusMd);
      expect(AppTheme.radiusPanel, AppTheme.radiusLg);
      expect(AppTheme.radiusHero, AppTheme.radiusMd);
    });

    test('warna permukaan dan overlay terdefinisi', () {
      expect(AppTheme.surface, Colors.white);
      expect(AppTheme.surfaceMuted, isNot(AppTheme.surface));
      expect(AppTheme.chipSurface, isNot(AppTheme.surfaceMuted));
      expect((AppTheme.overlayScrim.a * 255.0).round().clamp(0, 255),
          lessThan(255));
    });

    test('tema light dapat dibangun tanpa error', () {
      final theme = AppTheme.light();
      expect(theme, isNotNull);
      expect(theme.colorScheme.brightness, Brightness.light);
    });
  });
}
