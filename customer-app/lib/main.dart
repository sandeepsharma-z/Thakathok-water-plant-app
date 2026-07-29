import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/home_content_service.dart';
import 'services/plant_config.dart';
import 'services/app_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // Publishable (anon) key — safe to embed in the client.
    publishableKey: SupabaseConfig.anonKey,
  );
  // Pull live rate / delivery / contact from the admin-controlled settings.
  // Short timeout so a slow network never blocks app start (defaults kick in).
  try {
    await Future.wait([
      PlantConfig.instance.load(),
      HomeContentService.instance.load(),
      AppConfigService.instance.load(),
    ]).timeout(const Duration(seconds: 4));
  } catch (_) {
    // Ignore — PlantConfig keeps its fallback defaults.
  }
  runApp(const ThakaThokApp());
}

class ThakaThokApp extends StatelessWidget {
  const ThakaThokApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfigService.instance;
    return MaterialApp(
      title: '${config.brandName} — ${config.plantDisplayName}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.primaryColor,
          primary: config.primaryColor,
        ),
        scaffoldBackgroundColor: AppColors.scaffold,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Future<bool> _hasValidLocalSession() async {
    final mobile = await AuthService.instance.currentMobile();
    final token = await AuthService.instance.currentToken();
    return mobile != null && token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasValidLocalSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        return snapshot.data == true
            ? const SplashScreen()
            : const LoginScreen();
      },
    );
  }
}
