import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/font_licenses.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/deep_link_provider.dart';
import 'providers/event_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/setup/setup_required_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/push_messaging_service.dart';
import 'widgets/deep_link_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerFontLicenses();
  await initializeDateFormatting('id_ID');

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  final firebaseReady = await _initializeFirebase();
  if (firebaseReady) {
    await FirebasePushMessagingService.instance.initialize();
  }

  runApp(const EventKuyApp());
}

/// Inisialisasi Firebase bila konfigurasi tersedia.
///
/// Android memakai `android/app/google-services.json`; platform lain dapat
/// memakai `--dart-define=FIREBASE_*`. Kegagalan tidak menghentikan aplikasi
/// agar mode tanpa Firebase tetap bisa dibuka.
Future<bool> _initializeFirebase() async {
  final options = AppConfig.firebaseOptions;
  if (kIsWeb && options == null) {
    debugPrint('Firebase dilewati: opsi Firebase web belum diisi.');
    return false;
  }

  try {
    await Firebase.initializeApp(options: options);
    debugPrint('Firebase berhasil diinisialisasi.');
    return true;
  } catch (error) {
    debugPrint('Firebase gagal diinisialisasi: $error');
    return false;
  }
}

class EventKuyApp extends StatelessWidget {
  const EventKuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => DeepLinkProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: DeepLinkHost(
        child: MaterialApp(
          title: AppConfig.appName,
          theme: AppTheme.light(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AppConfig.hasSupabaseConfig
              ? const SplashScreen()
              : const SetupRequiredScreen(),
        ),
      ),
    );
  }
}
