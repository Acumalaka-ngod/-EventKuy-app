import 'package:flutter/material.dart';

/// Tema AjangIn — Desain Baru (bersih, putih, indigo).
/// Mengikuti mockup: latar putih, kartu ber-border halus, aksen Indigo.
class AppTheme {
  // Palet Warna Utama
  static const Color primary = Color(0xFF4338CA); // Indigo 700
  static const Color primaryDark = Color(0xFF312E81); // Indigo 900
  static const Color primaryLight = Color(0xFFEEF0FF); // Indigo soft
  static const Color secondary = Color(0xFFEF4466); // Coral / Red
  static const Color accentAmber = Color(0xFFF59E0B); // Amber
  static const Color accentEmerald = Color(0xFF10B981); // Emerald
  static const Color navy = Color(0xFF0F172A); // Slate 900
  static const Color background = Color(0xFFFFFFFF); // Putih bersih
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE9EAF0); // Border kartu halus
  static const Color field = Color(0xFFF4F4F7); // Isian input abu terang
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color chipSelected = Color(0xFF4338CA);

  // Gradien
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x22000000),
      Color(0xCC0B1020),
    ],
    stops: [0.35, 0.6, 1.0],
  );

  /// Gradien tiket: indigo → ungu → magenta → oranye (sesuai mockup e-ticket).
  static const LinearGradient ticketGradient = LinearGradient(
    colors: [
      Color(0xFF4338CA),
      Color(0xFF7C3AED),
      Color(0xFFD946EF),
      Color(0xFFFB923C),
    ],
    stops: [0.0, 0.4, 0.72, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradien splash & branding (navy dalam).
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF171D4B), Color(0xFF232A6B), Color(0xFF2E3480)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: card,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: const TextStyle(color: textGrey, fontSize: 13.5),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: textMuted, fontSize: 12.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.2),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
