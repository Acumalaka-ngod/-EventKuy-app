import 'package:flutter/material.dart';

/// Breakpoint global EventKuy (mengikuti prototipe Figma):
/// - Mobile  : lebar <= 720  (bottom bar mengambang)
/// - Tablet  : 720 - 1100    (rail ikon 88px)
/// - Desktop : > 1100        (sidebar 240px)
class Breakpoints {
  static const double mobile = 720;
  static const double tablet = 1100;

  /// Lebar maksimal konten agar tetap nyaman di layar besar.
  static const double contentMaxWidth = 1200;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeOf(double width) {
  if (width < Breakpoints.mobile) return DeviceType.mobile;
  if (width < Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Widget pembantu: memilih tampilan berdasarkan lebar layar.
/// [tablet] opsional — jika null akan memakai [desktop].
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (deviceTypeOf(constraints.maxWidth)) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? desktop;
          case DeviceType.desktop:
            return desktop;
        }
      },
    );
  }
}

/// Jumlah kolom grid poster event:
/// 2 (mobile), 3 (tablet), 4 (desktop).
int eventGridColumns(double width) {
  if (width < Breakpoints.mobile) return 2;
  if (width < Breakpoints.tablet) return 3;
  return 4;
}

/// Rasio kartu grid agar foto + info pas di tiap ukuran layar.
double eventGridAspect(double width) {
  if (width < Breakpoints.mobile) return 0.60;
  if (width < Breakpoints.tablet) return 0.82;
  return 0.90;
}

/// Padding horizontal konten adaptif.
double contentPadding(double width) {
  if (width < Breakpoints.mobile) return 18;
  if (width < Breakpoints.tablet) return 28;
  return 32;
}

/// Membungkus konten agar lebarnya maksimal [maxWidth] dan tetap di tengah.
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
