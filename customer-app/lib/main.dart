import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // Publishable (anon) key — safe to embed in the client.
    anonKey: SupabaseConfig.anonKey,
    // ignore: deprecated_member_use
  );
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
      home: const SplashScreen(),
    );
  }
}
