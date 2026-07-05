// =============================================================================
// PROGANA Fantasy — Modelo PredictionResult
// =============================================================================
//
//   ✓ Mapeo del contrato JSON PROGANA Predict
//   ✓ Ahora con DOS ángulos de marcador: global + condicionado al pick + nota
//
// Contrato JSON:
// {
//   "home": "...", "away": "...", "pick": "L|E|V", "pick_team": "...",
//   "confidence": 0.39,
//   "final_probs": {"L":..,"E":..,"V":..}, "model_probs": {...}, "market_probs": {...}|null,
//   "most_likely_score": [1, 1],            // marcador exacto más probable (global)
//   "most_likely_score_if_pick": [1, 0],    // marcador más probable SI gana el favorito
//   "score_note": "Lo más probable es que gane X, pero el marcador exacto es 1-1...",
//   "justification": "...", "historical_accuracy": 0.59
// }
// =============================================================================

library;

import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';

class PredictionResult {
  final String home;
  final String away;
  final String pick; // 'L' | 'E' | 'V'
  final String pickTeam;
  final double confidence;
  final Map<String, double> finalProbs;
  final Map<String, double> modelProbs;
  final Map<String, double>? marketProbs;

  /// Marcador exacto más probable (global). [1,1] = "1-1".
  final List<int>? mostLikelyScore;

  /// Marcador más probable CONDICIONADO a que gane el favorito. [1,0] = "1-0".
  final List<int>? mostLikelyScoreIfPick;

  /// Nota que explica ambos marcadores (español).
  final String? scoreNote;

  final String justification;
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
    this.mostLikelyScoreIfPick,
    this.scoreNote,
    required this.justification,
    required this.historicalAccuracy,
  });

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
      mostLikelyScoreIfPick: _parseScore(json['most_likely_score_if_pick']),
      scoreNote: json['score_note'] as String?,
      justification: (json['justification'] as String?) ??
          'Análisis disponible momentáneamente.',
      historicalAccuracy:
          (json['historical_accuracy'] as num?)?.toDouble() ?? 0.59,
    );
  }

  static Map<String, double> _parseProbs(dynamic raw) {
    if (raw is! Map) return {'L': 0.33, 'E': 0.33, 'V': 0.33};
    final result = <String, double>{};
    raw.forEach((key, value) {
      final k = key.toString();
      final v = (value as num?)?.toDouble() ?? 0.0;
      if (k == 'L' || k == 'E' || k == 'V') result[k] = v;
    });
    if (result.isEmpty) return {'L': 0.33, 'E': 0.33, 'V': 0.33};
    return result;
  }

  static List<int>? _parseScore(dynamic raw) {
    if (raw is! List) return null;
    if (raw.length != 2) return null;
    try {
      return [(raw[0] as num).toInt(), (raw[1] as num).toInt()];
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // GETTERS UI
  // ===========================================================================

  double get localPct => finalProbs['L'] ?? 0.0;
  double get empatePct => finalProbs['E'] ?? 0.0;
  double get visitaPct => finalProbs['V'] ?? 0.0;

  String get localPctStr => '${(localPct * 100).round()}%';
  String get empatePctStr => '${(empatePct * 100).round()}%';
  String get visitaPctStr => '${(visitaPct * 100).round()}%';

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

  /// Marcador global: [1,1] → "1 - 1". Null → "—".
  String get scoreDisplay {
    if (mostLikelyScore == null) return '—';
    return '${mostLikelyScore![0]} - ${mostLikelyScore![1]}';
  }

  /// Marcador si gana el favorito: [1,0] → "1 - 0". Null → "—".
  String get scoreIfPickDisplay {
    if (mostLikelyScoreIfPick == null) return '—';
    return '${mostLikelyScoreIfPick![0]} - ${mostLikelyScoreIfPick![1]}';
  }

  bool get hasScoreIfPick => mostLikelyScoreIfPick != null;

  String get accuracyDisplay => '~${(historicalAccuracy * 100).round()}%';
  String get confidenceDisplay => '${(confidence * 100).round()}%';
  bool get hasMarketData => marketProbs != null && marketProbs!.isNotEmpty;

  @override
  String toString() =>
      'PredictionResult($home vs $away, pick=$pick, conf=$confidenceDisplay)';
}
