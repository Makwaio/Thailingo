import 'package:flutter/material.dart';

class AppTheme {
  // Thai Flag Colors
  static const Color thaiRed    = Color(0xFFB5001C);
  static const Color thaiRedDk  = Color(0xFF8C0015);
  static const Color thaiNavy   = Color(0xFF2D2A6E);
  static const Color thaiNavyDk = Color(0xFF1E1B4E);
  static const Color thaiGold   = Color(0xFFD4A017);
  static const Color thaiGoldDk = Color(0xFFAA7D0E);
  static const Color thaiWhite  = Color(0xFFFFFFFF);

  // Semantic aliases (used throughout the app)
  static const Color primary    = thaiNavy;
  static const Color primaryDk  = thaiNavyDk;
  static const Color accent     = thaiGold;
  static const Color success    = Color(0xFF58CC02);
  static const Color successDk  = Color(0xFF46A302);
  static const Color danger     = thaiRed;
  static const Color dangerDk   = thaiRedDk;
  static const Color surface    = Color(0xFFF7F9FC);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE0E7F0);
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color locked     = Color(0xFFB0BEC5);

  // Tint backgrounds
  static const Color redTint    = Color(0xFFF8E8EA);
  static const Color blueTint   = Color(0xFFE8E8F8);

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
        colorScheme: ColorScheme.fromSeed(seedColor: thaiNavy, surface: surface),
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
