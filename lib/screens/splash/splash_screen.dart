import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/ticket_provider.dart';
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

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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

    if (auth.isLoggedIn) {
      await Future.wait([
        context.read<TicketProvider>().load().catchError((_) {}),
        context.read<FavoriteProvider>().load().catchError((_) {}),
      ]);
      if (!mounted) return;
    }

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
            // Lingkaran dekoratif
            Positioned(
              top: -200,
              right: -240,
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
              bottom: -190,
              left: -210,
              child: Container(
                width: 470,
                height: 470,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
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
                      const EventKuyLogo(
                        markSize: 52,
                        fontSize: 36,
                        onDark: true,
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'TEMUKAN • IKUTI • HADIRI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer versi
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Text(
                'Versi 1.0.0 · Mobile Event Ticketing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
