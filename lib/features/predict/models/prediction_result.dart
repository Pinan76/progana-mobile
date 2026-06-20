// =============================================================================
// PROGANA Fantasy — Modelo PredictionResult
// =============================================================================
//
// L41 COMPLIANT (15 jun 2026):
//   ✓ Mapeo directo del contrato JSON PROGANA Predict (Sección 3 handoff)
//   ✓ Factory.fromJson defensive
//   ✓ Getters UI para PredictCard (pickColor, scoreDisplay, etc.)
//   ✓ Sin dependencias (solo Flutter material + theme)
//
// Contrato JSON esperado del backend:
// {
//   "home": "México",
//   "away": "Brasil",
//   "pick": "V",                         // L | E | V
//   "pick_team": "Brasil",
//   "confidence": 0.45,
//   "final_probs":  {"L": 0.28, "E": 0.27, "V": 0.45},
//   "model_probs":  {"L": 0.39, "E": 0.30, "V": 0.31},
//   "market_probs": {"L": 0.30, "E": 0.25, "V": 0.45},
//   "most_likely_score": [1, 2],
//   "justification": "Modelo y mercado coinciden...",
//   "historical_accuracy": 0.59
// }
//
// =============================================================================

library;

import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';

class PredictionResult {
  /// Nombre equipo local
  final String home;

  /// Nombre equipo visitante
  final String away;

  /// Sugerencia IA: 'L', 'E', o 'V'
  final String pick;

  /// Nombre del equipo sugerido (para Display: "Brasil · V")
  final String pickTeam;

  /// Confianza de la sugerencia (0.0-1.0)
  final double confidence;

  /// Probabilidades finales L/E/V (suma 1.0)
  final Map<String, double> finalProbs;

  /// Probabilidades del modelo (Elo+Dixon-Coles) sin mercado
  final Map<String, double> modelProbs;

  /// Probabilidades del mercado (cuotas casa de apuestas)
  /// Puede ser null si no hay cuotas disponibles
  final Map<String, double>? marketProbs;

  /// Marcador más probable [golesLocal, golesVisita]
  /// Ejemplo: [1, 2] = "1-2"
  /// Puede ser null si no se pudo calcular
  final List<int>? mostLikelyScore;

  /// Justificación corta en español (1-2 líneas)
  final String justification;

  /// Precisión histórica del modelo (~0.59 según handoff)
  final double historicalAccuracy;

  const PredictionResult({
    required this.home,
    required this.away,
    required this.pick,
    required this.pickTeam,
    required this.confidence,
    required this.finalProbs,
    required this.modelProbs,
    this.marketProbs,
    this.mostLikelyScore,
    required this.justification,
    required this.historicalAccuracy,
  });

  // ===========================================================================
  // FACTORY DESERIALIZACIÓN JSON DEFENSIVA
  // ===========================================================================

  /// Crea PredictionResult desde JSON del backend
  ///
  /// L41 defensive: si campos faltan o tipos cambian, no crashea
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      home: (json['home'] as String?) ?? '?',
      away: (json['away'] as String?) ?? '?',
      pick: (json['pick'] as String?) ?? 'L',
      pickTeam: (json['pick_team'] as String?) ?? '?',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      finalProbs: _parseProbs(json['final_probs']),
      modelProbs: _parseProbs(json['model_probs']),
      marketProbs: json['market_probs'] != null
          ? _parseProbs(json['market_probs'])
          : null,
      mostLikelyScore: _parseScore(json['most_likely_score']),
      justification: (json['justification'] as String?) ??
          'Análisis disponible momentáneamente.',
      historicalAccuracy:
          (json['historical_accuracy'] as num?)?.toDouble() ?? 0.59,
    );
  }

  /// Helper privado: parsea map de probabilidades
  static Map<String, double> _parseProbs(dynamic raw) {
    if (raw is! Map) return {'L': 0.33, 'E': 0.33, 'V': 0.33};
    final result = <String, double>{};
    raw.forEach((key, value) {
      final k = key.toString();
      final v = (value as num?)?.toDouble() ?? 0.0;
      if (k == 'L' || k == 'E' || k == 'V') {
        result[k] = v;
      }
    });
    // Fallback si vino mal
    if (result.isEmpty) return {'L': 0.33, 'E': 0.33, 'V': 0.33};
    return result;
  }

  /// Helper privado: parsea marcador [int, int]
  static List<int>? _parseScore(dynamic raw) {
    if (raw is! List) return null;
    if (raw.length != 2) return null;
    try {
      return [
        (raw[0] as num).toInt(),
        (raw[1] as num).toInt(),
      ];
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // GETTERS UI PARA PredictCard
  // ===========================================================================

  /// Porcentaje L para barra (0.0-1.0)
  double get localPct => finalProbs['L'] ?? 0.0;

  /// Porcentaje E para barra (0.0-1.0)
  double get empatePct => finalProbs['E'] ?? 0.0;

  /// Porcentaje V para barra (0.0-1.0)
  double get visitaPct => finalProbs['V'] ?? 0.0;

  /// Porcentaje L formateado: "28%"
  String get localPctStr => '${(localPct * 100).round()}%';

  /// Porcentaje E formateado: "27%"
  String get empatePctStr => '${(empatePct * 100).round()}%';

  /// Porcentaje V formateado: "45%"
  String get visitaPctStr => '${(visitaPct * 100).round()}%';

  /// Color del pick para destacar en UI
  /// L → emerald, E → creamDim, V → gold
  Color get pickColor {
    switch (pick) {
      case 'L':
        return ProganaColors.emerald;
      case 'E':
        return ProganaColors.creamDim;
      case 'V':
        return ProganaColors.gold;
      default:
        return ProganaColors.cream;
    }
  }

  /// Etiqueta del pick: 'L' → 'LOCAL', 'E' → 'EMPATE', 'V' → 'VISITA'
  String get pickLabel {
    switch (pick) {
      case 'L':
        return 'LOCAL';
      case 'E':
        return 'EMPATE';
      case 'V':
        return 'VISITA';
      default:
        return pick;
    }
  }

  /// Marcador display: [1, 2] → "1 - 2"
  /// Si null → "—"
  String get scoreDisplay {
    if (mostLikelyScore == null) return '—';
    return '${mostLikelyScore![0]} - ${mostLikelyScore![1]}';
  }

  /// Accuracy histórica formateada: 0.59 → "~59%"
  String get accuracyDisplay {
    final pct = (historicalAccuracy * 100).round();
    return '~$pct%';
  }

  /// Confianza formateada: 0.45 → "45%"
  String get confidenceDisplay => '${(confidence * 100).round()}%';

  /// Indica si esta predicción tiene contexto de mercado (cuotas)
  bool get hasMarketData => marketProbs != null && marketProbs!.isNotEmpty;

  @override
  String toString() {
    return 'PredictionResult($home vs $away, pick=$pick, conf=$confidenceDisplay)';
  }
}