// =============================================================================
// PROGANA Fantasy — Modelo Prediccion
// =============================================================================
//
// Matchea tabla `predicciones` en Supabase.
//
// L41 COMPLIANT (2 jun 2026 - Día 7 PM):
//   ✓ Estructura verificada contra information_schema
//   ✓ Constraints check identificados: check_free_solo_resultado, check_pro_marcador
//   ✓ pred_resultado SIEMPRE obligatorio (incluso Plus/Pro con marcador)
//   ✓ UNIQUE constraint (user_id, partido_id, quiniela_id) → UPSERT behavior
//   ✓ Helper estático calcularResultado() para que Plus/Pro lo calculen auto
//
// FASE 2 - GOLEADOR (4 jun 2026 - Día 9 PM):
//   ✓ Campo goleadorPredichoId agregado (nullable INT, FK jugadores)
//   ✓ Constraints BD nuevos: check_free_no_goleador, check_goleador_sin_empate_cero
//   ✓ Trigger BD: trg_validar_goleador_pertenece_partido
//   ✓ puedeGoleador actualizado: Plus + Pro (Reglamento v1.2)
//
// Estructura BD:
//   id              uuid    DEFAULT uuid_generate_v4()
//   user_id         uuid    NOT NULL FK profiles(id)
//   partido_id      int     NOT NULL FK partidos(id)
//   quiniela_id     int     NOT NULL FK quinielas(id)
//   pred_local      int?    CHECK 0-20 (null para Free)
//   pred_visit      int?    CHECK 0-20 (null para Free)
//   pred_resultado  char    CHECK ['L','E','V'] OBLIGATORIO
//   tier_al_predecir tier_usuario NOT NULL ('free'/'plus'/'pro')
//   goleador_predicho_id int? FK jugadores(id) NULL (solo Plus/Pro)
//   fecha_prediccion timestamp DEFAULT now()
//   created_at, updated_at
//
// =============================================================================

/// Tier al momento de predecir (snapshot)
enum TierAlPredecir {
  free,
  plus,
  pro;

  static TierAlPredecir fromString(String value) {
    switch (value) {
      case 'free':
        return TierAlPredecir.free;
      case 'plus':
        return TierAlPredecir.plus;
      case 'pro':
        return TierAlPredecir.pro;
      default:
        return TierAlPredecir.free;
    }
  }

  String get value {
    switch (this) {
      case TierAlPredecir.free:
        return 'free';
      case TierAlPredecir.plus:
        return 'plus';
      case TierAlPredecir.pro:
        return 'pro';
    }
  }

  /// Tiers que pueden predecir marcador exacto
  bool get puedeMarcador =>
      this == TierAlPredecir.plus || this == TierAlPredecir.pro;

  /// Tiers que pueden predecir goleador (Reglamento v1.2: Plus + Pro)
  bool get puedeGoleador =>
      this == TierAlPredecir.plus || this == TierAlPredecir.pro;
}

/// Resultado de un partido (Local / Empate / Visitante)
class ResultadoPartido {
  static const String local = 'L';
  static const String empate = 'E';
  static const String visitante = 'V';

  /// Calcula L/E/V a partir de goles
  /// Usado por Plus/Pro al guardar marcador (BD requiere pred_resultado siempre)
  static String calcular(int golesLocal, int golesVisit) {
    if (golesLocal > golesVisit) return local;
    if (golesLocal < golesVisit) return visitante;
    return empate;
  }

  /// Etiqueta legible
  static String etiqueta(String resultado) {
    switch (resultado) {
      case local:
        return 'Local';
      case empate:
        return 'Empate';
      case visitante:
        return 'Visitante';
      default:
        return '—';
    }
  }
}

/// Modelo principal Prediccion
class Prediccion {
  final String id;
  final String userId;
  final int partidoId;
  final int quinielaId;
  final int? predLocal;          // null para Free
  final int? predVisit;          // null para Free
  final String predResultado;    // 'L', 'E', 'V' (siempre)
  final TierAlPredecir tierAlPredecir;
  final int? goleadorPredichoId; // FK jugadores.id (solo Plus/Pro, nullable)
  final DateTime fechaPrediccion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Prediccion({
    required this.id,
    required this.userId,
    required this.partidoId,
    required this.quinielaId,
    this.predLocal,
    this.predVisit,
    required this.predResultado,
    required this.tierAlPredecir,
    this.goleadorPredichoId,
    required this.fechaPrediccion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialización desde JSON de Supabase
  factory Prediccion.fromJson(Map<String, dynamic> json) {
    return Prediccion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      partidoId: json['partido_id'] as int,
      quinielaId: json['quiniela_id'] as int,
      predLocal: json['pred_local'] as int?,
      predVisit: json['pred_visit'] as int?,
      predResultado: json['pred_resultado'] as String,
      tierAlPredecir: TierAlPredecir.fromString(
        json['tier_al_predecir'] as String,
      ),
      goleadorPredichoId: json['goleador_predicho_id'] as int?,
      fechaPrediccion: DateTime.parse(json['fecha_prediccion'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ===========================================================================
  // GETTERS DE NEGOCIO
  // ===========================================================================

  /// Si la predicción tiene marcador exacto (Plus/Pro)
  bool get tieneMarcadorExacto => predLocal != null && predVisit != null;

  /// Si la predicción tiene goleador (solo Plus/Pro pueden tenerlo)
  bool get tieneGoleador => goleadorPredichoId != null;

  /// Marcador display: "2 - 1" o "—"
  String get marcadorDisplay {
    if (!tieneMarcadorExacto) return '—';
    return '$predLocal - $predVisit';
  }

  /// Resultado legible: "Local" / "Empate" / "Visitante"
  String get resultadoLegible => ResultadoPartido.etiqueta(predResultado);

  /// Si la predicción es de Free (solo L/E/V sin marcador)
  bool get esSoloResultado =>
      tierAlPredecir == TierAlPredecir.free || !tieneMarcadorExacto;

  @override
  String toString() {
    final goleadorStr = tieneGoleador ? ', goleador=$goleadorPredichoId' : '';
    return 'Prediccion(partido=$partidoId, '
        'marcador=$marcadorDisplay, '
        'resultado=$predResultado, '
        'tier=${tierAlPredecir.value}'
        '$goleadorStr)';
  }
}

/// Excepción específica al guardar predicción
class PrediccionException implements Exception {
  final String message;
  const PrediccionException(this.message);

  @override
  String toString() => message;
}

/// El partido ya cerró predicciones (ya empezó o ya terminó)
class PartidoCerradoException extends PrediccionException {
  const PartidoCerradoException()
      : super('Las predicciones para este partido ya están cerradas');
}

/// Tier no compatible con tipo de predicción
class TierInvalidoException extends PrediccionException {
  const TierInvalidoException(super.message);
}