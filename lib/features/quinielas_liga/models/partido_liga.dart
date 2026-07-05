/// Partido de clubes leído de la vista v_partidos_liga_detalle o del
/// RPC get_partidos_quiniela.
class PartidoLiga {
  final int id;
  final int competicionId;
  final String competicionCorto;
  final int? jornada;
  final String localNombre;
  final String visitanteNombre;
  final DateTime fechaHora;
  final String? estado;

  /// Escudos (crest) — desde la vista de selección. Pueden faltar
  /// (p.ej. get_partidos_quiniela no los expone) → la UI usa fallback.
  final String? localEscudo;
  final String? visitanteEscudo;

  const PartidoLiga({
    required this.id,
    required this.competicionId,
    required this.competicionCorto,
    this.jornada,
    required this.localNombre,
    required this.visitanteNombre,
    required this.fechaHora,
    this.estado,
    this.localEscudo,
    this.visitanteEscudo,
  });

  factory PartidoLiga.fromJson(Map<String, dynamic> json) {
    return PartidoLiga(
      id: json['id'] as int,
      competicionId: json['competicion_id'] as int,
      competicionCorto: (json['competicion_corto'] as String?) ?? '',
      jornada: json['jornada'] as int?,
      localNombre: (json['local_nombre'] as String?) ?? '',
      visitanteNombre: (json['visitante_nombre'] as String?) ?? '',
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      estado: json['estado'] as String?,
      localEscudo: json['local_escudo'] as String?,
      visitanteEscudo: json['visitante_escudo'] as String?,
    );
  }

  String get titulo => '$localNombre vs $visitanteNombre';

  /// Abierto a predicciones (heurística de UI; el servidor valida de verdad).
  bool get abierto => estado == null || estado == 'programado';
}

/// Competencia (liga) para los chips de selección.
class Competicion {
  final int id;
  final String nombre;
  final String nombreCorto;

  const Competicion({
    required this.id,
    required this.nombre,
    required this.nombreCorto,
  });

  factory Competicion.fromJson(Map<String, dynamic> json) {
    return Competicion(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      nombreCorto: (json['nombre_corto'] as String?) ?? '',
    );
  }
}
