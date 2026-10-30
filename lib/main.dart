import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/setup/setup_required_screen.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const EventKuyApp());
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
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: AppConfig.hasSupabaseConfig
            ? const SplashScreen()
            : const SetupRequiredScreen(),
      ),
    );
  }
}
