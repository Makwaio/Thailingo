import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary     = Color(0xFF1565C0);
  static const Color primaryDk   = Color(0xFF0D47A1);
  static const Color accent      = Color(0xFFFFC800);
  static const Color success     = Color(0xFF58CC02);
  static const Color successDk   = Color(0xFF46A302);
  static const Color danger      = Color(0xFFFF4B4B);
  static const Color dangerDk    = Color(0xFFCC0000);
  static const Color surface     = Color(0xFFF7F9FC);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFE0E7F0);
  static const Color textPrimary    = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color locked      = Color(0xFFB0BEC5);

  static const double radiusSm   = 10;
  static const double radiusMd   = 14;
  static const double radiusLg   = 20;
  static const double radiusXl   = 28;
  static const double radiusFull = 999;

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: surface),
        scaffoldBackgroundColor: surface,
        fontFamily: 'Sarabun',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textPrimary),
        ),
      );
}

extension HexColor on Color {
  static Color fromHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
