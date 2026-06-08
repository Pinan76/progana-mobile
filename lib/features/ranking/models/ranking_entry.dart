// =============================================================================
// PROGANA Fantasy — Modelo RankingEntry
// =============================================================================
//
// L41 COMPLIANT (8 jun 2026 - Día 10 PM):
//   ✓ Mapping a matview rankings_general (12 cols) y rankings_quiniela (13 cols)
//   ✓ Verificado contra information_schema 8 jun 2026
//   ✓ Helpers para UI: iniciales, displayName, tier badge
//
// Matviews backend:
// - rankings_general: ranking acumulado total (todas las quinielas)
// - rankings_quiniela: ranking por quiniela específica
//
// Refresh automático: trigger on_partido_finalizado llama refresh_rankings()
//
// =============================================================================

library;

/// Entry individual en el ranking
///
/// Mapea a 1 fila de matview rankings_general o rankings_quiniela.
/// Diferencia: rankings_quiniela tiene quiniela_id (filtro), general no.
class RankingEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String tier; // 'free' / 'plus' / 'pro'
  final double puntosTotales;
  final int totalExactos;
  final int totalCerca;
  final int totalGoleadores;
  final int totalResultado;
  final int totalCasi;
  final DateTime? registeredAt;
  final int posicion;

  // Solo en rankings_quiniela (null en general)
  final int? quinielaId;

  const RankingEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.tier,
    required this.puntosTotales,
    required this.totalExactos,
    required this.totalCerca,
    required this.totalGoleadores,
    required this.totalResultado,
    required this.totalCasi,
    this.registeredAt,
    required this.posicion,
    this.quinielaId,
  });

  /// Deserialización desde JSON Supabase
  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['user_id'] as String,
      username: (json['username'] as String?) ?? 'usuario',
      avatarUrl: json['avatar_url'] as String?,
      tier: (json['tier'] as String?) ?? 'free',
      puntosTotales: (json['puntos_totales'] as num?)?.toDouble() ?? 0.0,
      totalExactos: (json['total_exactos'] as num?)?.toInt() ?? 0,
      totalCerca: (json['total_cerca'] as num?)?.toInt() ?? 0,
      totalGoleadores: (json['total_goleadores'] as num?)?.toInt() ?? 0,
      totalResultado: (json['total_resultado'] as num?)?.toInt() ?? 0,
      totalCasi: (json['total_casi'] as num?)?.toInt() ?? 0,
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : null,
      posicion: (json['posicion'] as num?)?.toInt() ?? 0,
      quinielaId: json['quiniela_id'] as int?,
    );
  }

  // ===========================================================================
  // GETTERS UI
  // ===========================================================================

  /// Iniciales del username para avatar fallback
  /// Ejemplos: "jorge_pinan" → "JP", "ac" → "AC", "x" → "X"
  String get iniciales {
    if (username.isEmpty) return '?';

    // Separar por _ o espacios
    final parts = username.split(RegExp(r'[_\s]+'));

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();
  }

  /// Display name limpio para UI
  String get displayName {
    if (username.isEmpty) return 'Usuario';
    return username;
  }

  /// Puntos formateados como entero si no tiene decimales
  String get puntosDisplay {
    if (puntosTotales == puntosTotales.truncateToDouble()) {
      return puntosTotales.toInt().toString();
    }
    return puntosTotales.toStringAsFixed(1);
  }

  /// Tier display en mayúsculas
  String get tierDisplay => tier.toUpperCase();

  @override
  String toString() {
    return 'RankingEntry(pos: $posicion, $username, $puntosDisplay pts)';
  }
}