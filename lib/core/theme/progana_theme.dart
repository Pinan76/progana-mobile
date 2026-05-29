// =============================================================================
// PROGANA Fantasy — Flutter Theme
// Concepto: Midnight Stadium
// Versión: 1.0 — Mayo 2026
// L41: Verificado e integrado al proyecto 29 may 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// 1. PALETA DE COLORES
// =============================================================================

class ProganaColors {
  ProganaColors._();

  // --- FONDOS ---
  static const Color midnight = Color(0xFF0A0E1A);
  static const Color midnight2 = Color(0xFF131826);
  static const Color midnight3 = Color(0xFF1C2236);

  // --- ORO (PREMIUM / PREMIOS / CTAs) ---
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFF4C842);
  static const Color goldDark = Color(0xFF8B7521);

  // --- VERDE (PLUS / ÉXITO / CONFIRMACIÓN) ---
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDeep = Color(0xFF047857);

  // --- ROJO (PRO / URGENCIA / ERROR) ---
  static const Color crimson = Color(0xFFDC2626);
  static const Color crimsonDeep = Color(0xFF991B1B);

  // --- TEXTOS ---
  static const Color cream = Color(0xFFF5F0E8);
  static const Color creamDim = Color(0xFFC9C2B5);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyDark = Color(0xFF374151);

  // --- ALPHAS ÚTILES ---
  static Color goldOverlay(double opacity) => gold.withValues(alpha: opacity);
  static Color emeraldOverlay(double opacity) => emerald.withValues(alpha: opacity);
  static Color crimsonOverlay(double opacity) => crimson.withValues(alpha: opacity);
  static Color borderSubtle = Colors.white.withValues(alpha: 0.04);
  static Color borderGold = gold.withValues(alpha: 0.2);
}

// =============================================================================
// 2. TIPOGRAFÍA
// =============================================================================

class ProganaTextStyles {
  ProganaTextStyles._();

  // --- DISPLAY (Archivo Black) ---
  static TextStyle get displayLarge => GoogleFonts.archivoBlack(
    fontSize: 56,
    height: 0.88,
    letterSpacing: -1.5,
    color: ProganaColors.cream,
  );

  static TextStyle get displayMedium => GoogleFonts.archivoBlack(
    fontSize: 32,
    height: 1.0,
    letterSpacing: -0.5,
    color: ProganaColors.cream,
  );

  static TextStyle get displaySmall => GoogleFonts.archivoBlack(
    fontSize: 22,
    height: 1.0,
    letterSpacing: -0.3,
    color: ProganaColors.cream,
  );

  // --- HEADING (Archivo Black, más pequeño) ---
  static TextStyle get headingLarge => GoogleFonts.archivoBlack(
    fontSize: 18,
    color: ProganaColors.cream,
  );

  static TextStyle get headingMedium => GoogleFonts.archivoBlack(
    fontSize: 14,
    color: ProganaColors.cream,
  );

  static TextStyle get headingSmall => GoogleFonts.archivoBlack(
    fontSize: 13,
    color: ProganaColors.cream,
  );

  // --- BODY (Outfit) ---
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ProganaColors.cream,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ProganaColors.cream,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ProganaColors.creamDim,
  );

  // --- LABELS (JetBrains Mono) ---
  static TextStyle get labelLarge => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: ProganaColors.gold,
  );

  static TextStyle get labelMedium => GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: ProganaColors.creamDim,
  );

  static TextStyle get labelSmall => GoogleFonts.jetBrainsMono(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: ProganaColors.gold,
  );

  // --- NÚMEROS / SCORES (JetBrains Mono) ---
  static TextStyle get scoreXL => GoogleFonts.jetBrainsMono(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: ProganaColors.gold,
  );

  static TextStyle get scoreLarge => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ProganaColors.cream,
  );

  static TextStyle get scoreMedium => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ProganaColors.gold,
  );

  // --- BOTONES ---
  static TextStyle get button => GoogleFonts.archivoBlack(
    fontSize: 13,
    letterSpacing: 1.3,
    color: ProganaColors.midnight,
  );

  static TextStyle get buttonSmall => GoogleFonts.archivoBlack(
    fontSize: 11,
    letterSpacing: 1.5,
    color: ProganaColors.midnight,
  );
}

// =============================================================================
// 3. DIMENSIONES Y ESPACIADO
// =============================================================================

class ProganaSpacing {
  ProganaSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);
}

class ProganaRadius {
  ProganaRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 100.0;

  static BorderRadius get card => BorderRadius.circular(12);
  static BorderRadius get cardLarge => BorderRadius.circular(16);
  static BorderRadius get button => BorderRadius.circular(8);
  static BorderRadius get pill => BorderRadius.circular(100);
}

// =============================================================================
// 4. DECORACIONES REUTILIZABLES
// =============================================================================

class ProganaDecorations {
  ProganaDecorations._();

  static BoxDecoration card = BoxDecoration(
    color: ProganaColors.midnight2,
    borderRadius: ProganaRadius.card,
    border: Border.all(color: ProganaColors.borderSubtle),
  );

  static BoxDecoration cardGold = BoxDecoration(
    gradient: LinearGradient(
      colors: [ProganaColors.midnight2, ProganaColors.midnight3],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: ProganaRadius.cardLarge,
    border: Border.all(color: ProganaColors.borderGold),
  );

  static BoxDecoration cardPro = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        ProganaColors.gold.withValues(alpha: 0.15),
        ProganaColors.crimson.withValues(alpha: 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: ProganaRadius.cardLarge,
    border: Border.all(color: ProganaColors.gold, width: 2),
    boxShadow: [
      BoxShadow(
        color: ProganaColors.gold.withValues(alpha: 0.2),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration goldGlow({double opacity = 0.3}) => BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: ProganaColors.gold.withValues(alpha: opacity),
        blurRadius: 32,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration backgroundAtmospheric = const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.0, -0.7),
      radius: 1.2,
      colors: [
        Color(0x14D4AF37),
        Color(0x00000000),
      ],
    ),
  );

  static BoxDecoration bottomNav = BoxDecoration(
    color: ProganaColors.midnight2,
    border: Border(
      top: BorderSide(color: ProganaColors.gold.withValues(alpha: 0.1)),
    ),
  );
}

// =============================================================================
// 5. THEME DATA COMPLETO
// =============================================================================

class ProganaTheme {
  ProganaTheme._();

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    // === COLORES BASE ===
    primaryColor: ProganaColors.gold,
    scaffoldBackgroundColor: ProganaColors.midnight,
    canvasColor: ProganaColors.midnight,

    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: ProganaColors.gold,
      onPrimary: ProganaColors.midnight,
      secondary: ProganaColors.emerald,
      onSecondary: ProganaColors.midnight,
      tertiary: ProganaColors.crimson,
      onTertiary: ProganaColors.cream,
      error: ProganaColors.crimson,
      onError: ProganaColors.cream,
      surface: ProganaColors.midnight2,
      onSurface: ProganaColors.cream,
    ),

    // === TIPOGRAFÍA ===
    textTheme: TextTheme(
      displayLarge: ProganaTextStyles.displayLarge,
      displayMedium: ProganaTextStyles.displayMedium,
      displaySmall: ProganaTextStyles.displaySmall,
      headlineLarge: ProganaTextStyles.headingLarge,
      headlineMedium: ProganaTextStyles.headingMedium,
      headlineSmall: ProganaTextStyles.headingSmall,
      bodyLarge: ProganaTextStyles.bodyLarge,
      bodyMedium: ProganaTextStyles.bodyMedium,
      bodySmall: ProganaTextStyles.bodySmall,
      labelLarge: ProganaTextStyles.labelLarge,
      labelMedium: ProganaTextStyles.labelMedium,
      labelSmall: ProganaTextStyles.labelSmall,
    ),

    // === APP BAR ===
    appBarTheme: AppBarTheme(
      backgroundColor: ProganaColors.midnight,
      foregroundColor: ProganaColors.cream,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: ProganaTextStyles.headingMedium,
      iconTheme: const IconThemeData(color: ProganaColors.gold),
    ),

    // === BOTONES ELEVATED ===
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ProganaColors.gold,
        foregroundColor: ProganaColors.midnight,
        elevation: 8,
        shadowColor: ProganaColors.gold.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: ProganaRadius.button),
        textStyle: ProganaTextStyles.button,
      ),
    ),

    // === BOTONES OUTLINED ===
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ProganaColors.cream,
        side: BorderSide(color: ProganaColors.gold.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: ProganaRadius.button),
        textStyle: ProganaTextStyles.button.copyWith(color: ProganaColors.cream),
      ),
    ),

    // === BOTONES TEXT ===
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ProganaColors.gold,
        textStyle: ProganaTextStyles.labelLarge,
      ),
    ),

    // === CARDS ===
    cardTheme: CardThemeData(
      color: ProganaColors.midnight2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ProganaRadius.card,
        side: BorderSide(color: ProganaColors.borderSubtle),
      ),
    ),

    // === INPUTS ===
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ProganaColors.midnight2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: ProganaRadius.button,
        borderSide: BorderSide(color: ProganaColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: ProganaRadius.button,
        borderSide: BorderSide(color: ProganaColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: ProganaRadius.button,
        borderSide: const BorderSide(color: ProganaColors.gold, width: 2),
      ),
      labelStyle: ProganaTextStyles.labelMedium,
      hintStyle: ProganaTextStyles.bodyMedium.copyWith(
        color: ProganaColors.creamDim,
      ),
    ),

    // === BOTTOM NAVIGATION ===
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ProganaColors.midnight2,
      selectedItemColor: ProganaColors.gold,
      unselectedItemColor: ProganaColors.grey,
      selectedLabelStyle: ProganaTextStyles.labelSmall,
      unselectedLabelStyle: ProganaTextStyles.labelSmall.copyWith(
        color: ProganaColors.grey,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // === DIVIDER ===
    dividerTheme: DividerThemeData(
      color: ProganaColors.gold.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),

    // === ICON ===
    iconTheme: const IconThemeData(
      color: ProganaColors.cream,
      size: 20,
    ),

    // === PROGRESS INDICATORS ===
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ProganaColors.gold,
      linearTrackColor: ProganaColors.midnight2,
      circularTrackColor: ProganaColors.midnight2,
    ),

    // === SWITCHES Y CHECKBOXES ===
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return ProganaColors.gold;
        return ProganaColors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ProganaColors.gold.withValues(alpha: 0.3);
        }
        return ProganaColors.midnight2;
      }),
    ),

    // === SNACKBAR ===
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ProganaColors.midnight3,
      contentTextStyle: ProganaTextStyles.bodyMedium,
      actionTextColor: ProganaColors.gold,
      shape: RoundedRectangleBorder(borderRadius: ProganaRadius.button),
      behavior: SnackBarBehavior.floating,
    ),

    // === DIALOG ===
    dialogTheme: DialogThemeData(
      backgroundColor: ProganaColors.midnight2,
      shape: RoundedRectangleBorder(borderRadius: ProganaRadius.cardLarge),
      titleTextStyle: ProganaTextStyles.headingLarge,
      contentTextStyle: ProganaTextStyles.bodyMedium,
    ),
  );
}