import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../auth/login_screen.dart';
import '../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _boot();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await auth.tryAutoLogin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, anim, secAnim) =>
            auth.isLoggedIn ? const MainNavigation() : const LoginScreen(),
        transitionsBuilder: (context, animation, secAnim, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.splashGradient,
        ),
        child: Stack(
          children: [
            // Gelombang dekoratif bawah (sesuai mockup)
            const Positioned.fill(
              child: CustomPaint(painter: _WavePainter()),
            ),

            // Konten utama
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AjanginMark(size: 116, onDark: true),
                      const SizedBox(height: 32),
                      const Text(
                        'AJANGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TEMUKAN. IKUTI. HADIRI.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
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

/// Gelombang berlapis di bagian bawah splash.
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.78;

    void wave(double y, double amp, double phase, Color color) {
      final path = Path()..moveTo(0, y);
      path.quadraticBezierTo(
        w * 0.25, y - amp * 2.2, w * 0.5, y - amp);
      path.cubicTo(
        w * 0.68, y + amp * 0.7, w * 0.82, y - amp * 1.4, w, y - amp * 0.2);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    wave(baseY + 40, 26, 0, const Color(0xFF3B42A8).withValues(alpha: 0.55));
    wave(baseY + 78, 30, 1, const Color(0xFF4F46E5).withValues(alpha: 0.65));
    wave(baseY + 122, 24, 2, const Color(0xFF6D5CF0).withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
