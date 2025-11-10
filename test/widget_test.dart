import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta base: amarillo, blanco, beige.
const Color kYellow = Color(0xFFFFD54F);
const Color kBeige  = Color(0xFFF5E9DA);
const Color kWhite  = Color(0xFFFFFFFF);

/// Acentos por norma:
/// APA -> azul, IEEE -> rojo
const Color kAPA   = Color(0xFF1465BB);
const Color kIEEE  = Color(0xFFE53935);

ThemeData buildBaseTheme() {
  // Puedes activar Material 3 si lo deseas:
  final base = ThemeData(useMaterial3: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: kYellow,
      secondary: kBeige,
      surface: kWhite,
      background: kBeige,
    ),
    scaffoldBackgroundColor: kBeige,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: kWhite,
      foregroundColor: Colors.black87,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black45, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    // 🔧 Antes: CardTheme(...). Ahora debe ser CardThemeData(...)
    cardTheme: CardThemeData(
      color: kWhite,
      elevation: 2,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

