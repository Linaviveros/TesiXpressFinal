import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ====================== PALETA BASE (negro / blanco / beige) ======================
class AppColors {
  // Neutros
  static const black  = Color(0xFF0C0F14);
  static const ink    = Color(0xFF12151B);
  static const white  = Color(0xFFFFFFFF);
  static const beige  = Color(0xFFF4EDE3);

  // Contornos y superficies
  static const outline     = Color(0x1AFFFFFF); // blanco 10%
  static const outlineDark = Color(0x1A000000); // negro 10%
  static const panel       = Color(0x14FFFFFF); // glass 8%
  static const panelDark   = Color(0x14000000); // glass 8%

  // Acentos existentes en tu app (mantener funcionalidad APA/IEEE)
  static const kAPA  = Color(0xFF1465BB);
  static const kIEEE = Color(0xFFE53935);
}

/// ====================== TIPOGRAFÍA ======================
final _text = GoogleFonts.poppinsTextTheme();

/// ====================== LIGHT THEME (beige limpio) ======================
ThemeData buildLightTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.beige,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.black,
      onPrimary: AppColors.white,
      surface: AppColors.white,
      background: AppColors.beige,
    ),
    textTheme: _text.apply(
      bodyColor: AppColors.black,
      displayColor: AppColors.black,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 1.6, color: AppColors.black),
      ),
    ),
    // >>> CORREGIDO: CardThemeData (no CardTheme)
    cardTheme: const CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.outlineDark),
      ),
    ),
    dividerColor: AppColors.outlineDark,
  );
}

/// ====================== DARK THEME (futurista alto contraste) ======================
ThemeData buildDarkTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ink,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.white,
      surface: AppColors.ink,
      background: AppColors.ink,
    ),
    textTheme: _text.apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.white,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0x1AFFFFFF), // glass
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 1.6, color: AppColors.white),
      ),
    ),
    // >>> CORREGIDO: CardThemeData (no CardTheme)
    cardTheme: const CardThemeData(
      color: Color(0x0DFFFFFF), // glass sutil
      elevation: 0,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.outline),
      ),
    ),
    dividerColor: AppColors.outline,
  );
}

/// Compatibilidad con tu código anterior (si en algún punto llamas esto).
ThemeData buildBaseTheme() => buildLightTheme();

/// Exporta los acentos que ya usabas
const Color kAPA  = AppColors.kAPA;
const Color kIEEE = AppColors.kIEEE;
const Color kWhite = AppColors.white;
const Color kBeige = AppColors.beige;
