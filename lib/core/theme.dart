import 'package:flutter/material.dart';

/// Tema EventKuy.
///
/// Arah: "program acara cetak" — kertas hangat, tinta hampir hitam, satu aksen
/// vermilion, dan garis rambut sebagai pemisah. Gradien dekoratif dan shadow
/// lebar sudah dihapus; kedalaman dibentuk oleh border 1px, bukan glow.
///
/// Nama token lama (`violet`, `violetDark`, `violetSoft`) sengaja dipertahankan
/// supaya seluruh pemanggil lama tetap jalan tanpa diubah.
class AppTheme {
  AppTheme._();

  // ── Font ────────────────────────────────────────────────────────────
  static const String headingFont = 'Manrope';
  static const String bodyFont = 'DMSans';

  // ── Palet utama ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFF161310);
  static const Color muted = Color(0xFF6D665B);
  static const Color violet = Color(0xFFC63C14);
  static const Color violetDark = Color(0xFF8F2A0D);
  static const Color violetSoft = Color(0xFFFAE7DF);
  static const Color coral = Color(0xFFC63C14);
  static const Color green = Color(0xFF1B7A5B);
  static const Color greenSoft = Color(0xFFE7F3EE);
  static const Color red = Color(0xFFB3261E);
  static const Color redSoft = Color(0xFFFBEAE7);
  static const Color amber = Color(0xFF8A5A0B);
  static const Color amberSoft = Color(0xFFFBF0DC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8F8FB);
  static const Color chipSurface = Color(0xFFF0F0F5);
  static const Color canvas = Color(0xFFF4F1E8);
  static const Color fieldBg = Color(0xFFFBF8F1);
  static const Color textFaint = Color(0xFF736C60);
  static const Color overlayScrim = Color(0x33000000);

  // ── Alias kompatibel dengan kode lama ──────────────────────────────
  static const Color primary = violet;
  static const Color primaryDark = violetDark;
  static const Color primaryLight = violetSoft;
  static const Color secondary = coral;
  static const Color accentAmber = amber;
  static const Color accentEmerald = green;
  static const Color navy = ink;
  static const Color background = canvas;
  static const Color card = surface;
  static const Color border = Color(0xFFE3DCCF);
  static const Color field = fieldBg;
  static const Color textDark = ink;
  static const Color textMuted = muted;
  static const Color textGrey = textFaint;
  static const Color chipSelected = ink;

  // ── Radius ──────────────────────────────────────────────────────────
  // Skala tunggal: xs < sm < md < lg < xl < 2xl < 3xl < pill.
  static const double radiusXs = 3;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 14;
  static const double radiusXl = 20;
  static const double radius2xl = 28;
  static const double radius3xl = 32;
  static const double radiusPill = 999;

  // Alias kompatibel dengan kode lama.
  static const double radiusButton = radiusSm;
  static const double radiusField = radiusSm;
  static const double radiusCard = radiusMd;
  static const double radiusPanel = radiusLg;
  static const double radiusHero = radiusMd;

  // ── Shadow ──────────────────────────────────────────────────────────
  /// Shadow kartu: setipis garis, bukan glow.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A161310),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x06161310),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Tombol tidak lagi memakai shadow.
  static const List<BoxShadow> buttonShadow = [];

  /// Logo tidak lagi memakai shadow.
  static const List<BoxShadow> logoShadow = [];

  // ── Isian datar (pengganti gradien dekoratif) ───────────────────────
  /// Tombol primary — tinta pekat, bukan gradien.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [ink, ink],
  );

  /// Logo mark — vermilion datar.
  static const LinearGradient logoGradient = LinearGradient(
    colors: [violet, violet],
  );

  /// Scrim foto hero detail (fungsional, untuk keterbacaan teks).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00161310),
      Color(0x00161310),
      Color(0xB3161310),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Header kartu e-tiket — blok tinta penuh.
  static const LinearGradient ticketGradient = LinearGradient(
    colors: [ink, ink],
  );

  /// Splash — tinta penuh.
  static const LinearGradient splashGradient = LinearGradient(
    colors: [ink, ink],
  );

  /// Kartu profil — tinta penuh.
  static const LinearGradient profileGradient = LinearGradient(
    colors: [ink, ink],
  );

  /// Panel branding halaman auth — tinta penuh.
  static const LinearGradient authBrandGradient = LinearGradient(
    colors: [ink, ink],
  );

  /// Avatar profil — vermilion datar.
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [violet, violet],
  );

  // ── Teks ────────────────────────────────────────────────────────────
  static TextStyle get h1 => const TextStyle(
        fontFamily: headingFont,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.12,
        color: ink,
      );

  static TextStyle get h2 => const TextStyle(
        fontFamily: headingFont,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.2,
        color: ink,
      );

  static TextStyle get h3 => const TextStyle(
        fontFamily: headingFont,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: ink,
      );

  /// Label kecil di atas judul. Dulu berwarna aksen; sekarang tinta redup
  /// supaya tidak bersaing dengan judul.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: bodyFont,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: muted,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    height: 1.6,
    color: ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    height: 1.55,
    color: muted,
  );

  // ── ThemeData ───────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: violet,
      primary: violet,
      onPrimary: Colors.white,
      secondary: ink,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      error: red,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: bodyFont,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: bodyFont, bodyColor: ink, displayColor: ink)
          .copyWith(
            displayLarge: h1,
            displayMedium: h1,
            displaySmall: h2,
            headlineLarge: h1,
            headlineMedium: h2,
            headlineSmall: h2,
            titleLarge: h2,
            titleMedium: h3,
            titleSmall: const TextStyle(
              fontFamily: headingFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            labelLarge: const TextStyle(
              fontFamily: bodyFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: ink, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ink,
        labelStyle: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          side: const BorderSide(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBg,
        hintStyle: const TextStyle(
          fontFamily: bodyFont,
          color: textFaint,
          fontSize: 13.5,
        ),
        labelStyle: const TextStyle(
          fontFamily: bodyFont,
          color: textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: bodyFont,
          color: ink,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: ink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: const BorderSide(color: border, width: 1),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: violetDark,
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: muted,
        indicatorColor: violet,
        dividerColor: border,
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ink
              : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        side: const BorderSide(color: border, width: 1.4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: Colors.white,
      ),
    );
  }
}
