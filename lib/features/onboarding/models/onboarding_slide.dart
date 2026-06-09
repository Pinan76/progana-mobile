// =============================================================================
// PROGANA Fantasy — Modelo OnboardingSlide
// =============================================================================
//
// L41 COMPLIANT (8 jun 2026 - Día 10 PM):
//   ✓ Modelo inmutable para slides de onboarding
//   ✓ Soporta emoji, título, subtítulo, descripción, CTA
//   ✓ 4 slides Mundial 2026 hardcoded (no requieren BD)
//
// Slides:
// 1. BIENVENIDA: ¿qué es PROGANA?
// 2. CÓMO FUNCIONA: predice partidos + gana puntos
// 3. TIERS: Free / Plus / Pro
// 4. CTA: ¡inscríbete!
//
// =============================================================================

library;

import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';

/// Slide individual del onboarding
class OnboardingSlide {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final Color colorAccent;
  final List<String>? bulletPoints;

  const OnboardingSlide({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.colorAccent,
    this.bulletPoints,
  });
}

/// Definición estática de los 4 slides Mundial 2026
class OnboardingSlides {
  /// Lista de los 4 slides (Bienvenida + Cómo + Tiers + CTA)
  static List<OnboardingSlide> get all => [
        // SLIDE 1 — BIENVENIDA
        const OnboardingSlide(
          emoji: '⚽',
          titulo: '¡BIENVENIDO A\nPROGANA!',
          subtitulo: 'EL MUNDIAL ESTÁ AQUÍ',
          descripcion:
              'Compite con miles de aficionados. Predice los resultados del Mundial 2026 y gana premios reales.',
          colorAccent: ProganaColors.gold,
        ),

        // SLIDE 2 — CÓMO FUNCIONA
        const OnboardingSlide(
          emoji: '🎯',
          titulo: 'PREDICE Y\nGANA PUNTOS',
          subtitulo: 'ASÍ FUNCIONA',
          descripcion:
              'Predice los marcadores de los partidos. Mientras más exacta tu predicción, más puntos ganas.',
          colorAccent: ProganaColors.emerald,
          bulletPoints: [
            '⚡ EXACTO (3-1) → máximos puntos',
            '🎯 CERCA (3-0 ≈ 3-1) → buenos puntos',
            '✓ RESULTADO (gana México) → puntos base',
          ],
        ),

        // SLIDE 3 — TIERS
        const OnboardingSlide(
          emoji: '⭐',
          titulo: '3 NIVELES,\nA TU MEDIDA',
          subtitulo: 'ELIGE TU PLAN',
          descripcion:
              'Empieza GRATIS. Sube a PLUS para predecir marcadores y goleador. PRO para todo + ligas privadas.',
          colorAccent: ProganaColors.gold,
          bulletPoints: [
            'FREE → predicciones L/E/V',
            'PLUS \$25/mes → marcador + goleador',
            'PRO \$49/mes → todo + ligas privadas',
          ],
        ),

        // SLIDE 4 — CTA
        const OnboardingSlide(
          emoji: '🏆',
          titulo: '¡EMPIEZA\nA JUGAR!',
          subtitulo: 'EL MUNDIAL ARRANCA EL 11 JUN',
          descripcion:
              'La quiniela "Apertura Mundial" está abierta. Inscríbete antes del primer partido y compite con todos.',
          colorAccent: ProganaColors.emerald,
        ),
      ];

  /// Cantidad total de slides
  static int get count => all.length;
}