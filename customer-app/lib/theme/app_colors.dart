import 'package:flutter/material.dart';

/// Central colour palette for the ThakaThok / Mahalakshmi Water Plant app.
/// Blue water theme picked to match the approved home-screen styling.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B6FE3);
  static const Color primaryDark = Color(0xFF0B4DA2);
  static const Color primaryLight = Color(0xFF3E93F5);
  static const Color accent = Color(0xFF37B6FF);

  static const Color scaffold = Color(0xFFF5F9FF);
  static const Color surface = Colors.white;
  static const Color chipBg = Color(0xFFEAF3FF);

  static const Color textDark = Color(0xFF0E2A47);
  static const Color textMuted = Color(0xFF6B7C93);

  static const Color splashTop = Color(0xFF9BD4FA);
  static const Color splashBottom = Color(0xFFCDEBFF);

  // ── Figma design tokens ──────────────────────────────────────────
  static const Color brand = Color(0xFF004FDA); // #004FDA
  static const Color heading = Color(0xFF004ED9); // #004ED9
  static const Color body = Color(0xFF484C52); // #484C52
  static const Color offerBg = Color(0xFFEBF4FD); // #EBF4FD
  static const Color tint = Color(0x47BDDBF1); // #BDDBF147
  static const Color hairline = Color(0x14000000); // #00000014
  static const Color cardBorder = Color(0x1F000000); // #0000001F
  static const Color searchBtn = Color(0xB0004FDA); // #004FDAB0
  static const Color dashed = Color(0xFF015EC4); // #015EC4
  static const Color hint = Color(0xFF9AA1AC);

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2E8BF0), Color(0xFF0B4DA2)],
  );
}
