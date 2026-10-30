import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/event_image.dart';

/// Layout halaman auth: brand panel gradient di kiri (desktop),
/// form maksimal 470px di kanan. Mobile hanya menampilkan form + logo.
class AuthLayout extends StatelessWidget {
  final Widget form;

  const AuthLayout({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveLayout(
        mobile: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EventKuyLogo(markSize: 34, fontSize: 19),
                    const SizedBox(height: 44),
                    form,
                  ],
                ),
              ),
            ),
          ),
        ),
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 5, child: _BrandPanel()),
            Expanded(
              flex: 6,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: form,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 640),
      decoration: const BoxDecoration(
        gradient: AppTheme.authBrandGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            right: -230,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -160,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.coral.withValues(alpha: 0.16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const EventKuyLogo(
                  markSize: 38,
                  fontSize: 20,
                  onDark: true,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TEMUKAN • IKUTI • HADIRI',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Satu tempat untuk setiap momen yang berarti.',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2.2,
                              height: 1.05,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Dari panggung musik hingga ruang penuh inspirasi. Temukan pengalaman berikutnya bersama EventKuy.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 15,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: EventImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1670028514318-0ac718c0590d?auto=format&fit=crop&w=1200&q=86',
                          eventId: 'auth-preview',
                          width: 150,
                          height: 126,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EVENT PILIHAN MINGGU INI',
                              style: TextStyle(
                                color: Color(0xFFFFF0A4),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'We The Fest 2025',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.headingFont,
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '25 Juli · Jakarta',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
