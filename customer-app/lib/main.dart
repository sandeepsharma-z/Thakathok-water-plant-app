import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/plant_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // Publishable (anon) key — safe to embed in the client.
    anonKey: SupabaseConfig.anonKey,
    // ignore: deprecated_member_use
  );
  // Pull live rate / delivery / contact from the admin-controlled settings.
  // Short timeout so a slow network never blocks app start (defaults kick in).
  try {
    await PlantConfig.instance.load().timeout(const Duration(seconds: 3));
  } catch (_) {
    // Ignore — PlantConfig keeps its fallback defaults.
  }
  runApp(const ThakaThokApp());
}

class ThakaThokApp extends StatelessWidget {
  const ThakaThokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThakaThok — Mahalakshmi Water Plant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.instance.currentMobile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        return snapshot.data == null
            ? const LoginScreen()
            : const SplashScreen();
      },
    );
  }
}
