import 'equipo.dart';

/// Modelo Partido - matchea tabla `partidos` en Supabase
/// 
/// L41: Verificado contra information_schema 22 may 2026
/// Enums: fase_mundial, estado_partido

/// Fases del Mundial 2026
enum FaseMundial {
  gruposJ1,   // Grupos Jornada 1
  gruposJ2,   // Grupos Jornada 2
  gruposJ3,   // Grupos Jornada 3
  r32,        // Dieciseisavos
  octavos,
  cuartos,
  semis,
  tercer,     // Tercer y cuarto lugar
  final_;     // Final

  static FaseMundial fromString(String value) {
    switch (value) {
      case 'grupos_j1':
        return FaseMundial.gruposJ1;
      case 'grupos_j2':
        return FaseMundial.gruposJ2;
      case 'grupos_j3':
        return FaseMundial.gruposJ3;
      case 'r32':
        return FaseMundial.r32;
      case 'octavos':
        return FaseMundial.octavos;
      case 'cuartos':
        return FaseMundial.cuartos;
      case 'semis':
        return FaseMundial.semis;
      case 'tercer':
        return FaseMundial.tercer;
      case 'final':
        return FaseMundial.final_;
      default:
        return FaseMundial.gruposJ1;
    }
  }

  String get etiqueta {
    switch (this) {
      case FaseMundial.gruposJ1:
        return 'Grupos · Jornada 1';
      case FaseMundial.gruposJ2:
        return 'Grupos · Jornada 2';
      case FaseMundial.gruposJ3:
        return 'Grupos · Jornada 3';
      case FaseMundial.r32:
        return 'Dieciseisavos';
      case FaseMundial.octavos:
        return 'Octavos de Final';
      case FaseMundial.cuartos:
        return 'Cuartos de Final';
      case FaseMundial.semis:
        return 'Semifinales';
      case FaseMundial.tercer:
        return 'Tercer Lugar';
      case FaseMundial.final_:
        return 'FINAL';
    }
  }
}

/// Estado del partido
enum EstadoPartido {
  programado,
  cerradoPred,   // Cerrado a predicciones (ya empezó o por empezar)
  enJuego,
  finalizado,
  cancelado;

  static EstadoPartido fromString(String value) {
    switch (value) {
      case 'programado':
        return EstadoPartido.programado;
      case 'cerrado_pred':
        return EstadoPartido.cerradoPred;
      case 'en_juego':
        return EstadoPartido.enJuego;
      case 'finalizado':
        return EstadoPartido.finalizado;
      case 'cancelado':
        return EstadoPartido.cancelado;
      default:
        return EstadoPartido.programado;
    }
  }

  String get etiqueta {
    switch (this) {
      case EstadoPartido.programado:
        return 'Programado';
      case EstadoPartido.cerradoPred:
        return 'Cerrado';
      case EstadoPartido.enJuego:
        return 'EN VIVO';
      case EstadoPartido.finalizado:
        return 'Final';
      case EstadoPartido.cancelado:
        return 'Cancelado';
    }
  }

  bool get permitePredecir => this == EstadoPartido.programado;
  bool get yaFinalizo => this == EstadoPartido.finalizado;
}

/// Modelo principal Partido
/// 
/// IMPORTANTE: equipoLocal y equipoVisit pueden ser NULL
/// (ej: en eliminatorias antes de definirse el ganador)
class Partido {
  final int id;
  final FaseMundial fase;
  final int numeroPartido;
  final int? equipoLocalId;
  final int? equipoVisitId;
  final Equipo? equipoLocal;
  final Equipo? equipoVisit;
  final DateTime fechaHora;
  final DateTime fechaCierrePredicciones;
  final String? ciudad;
  final String? estadio;
  final String? pais;
  final EstadoPartido estado;
  final int? golesLocal;
  final int? golesVisit;
  final String? resultado;       // L/E/V
  final double multiplicador;
  final int? ordenEnQuiniela;    // Solo si viene de partidos_quiniela

  const Partido({
    required this.id,
    required this.fase,
    required this.numeroPartido,
    this.equipoLocalId,
    this.equipoVisitId,
    this.equipoLocal,
    this.equipoVisit,
    required this.fechaHora,
    required this.fechaCierrePredicciones,
    this.ciudad,
    this.estadio,
    this.pais,
    required this.estado,
    this.golesLocal,
    this.golesVisit,
    this.resultado,
    required this.multiplicador,
    this.ordenEnQuiniela,
  });

  factory Partido.fromJson(Map<String, dynamic> json) {
    // Si vienen equipos embebidos (JOIN), parsearlos
    Equipo? local;
    Equipo? visit;

    if (json['equipo_local'] != null) {
      local = Equipo.fromJson(json['equipo_local'] as Map<String, dynamic>);
    }
    if (json['equipo_visit'] != null) {
      visit = Equipo.fromJson(json['equipo_visit'] as Map<String, dynamic>);
    }

    return Partido(
      id: json['id'] as int,
      fase: FaseMundial.fromString(json['fase'] as String),
      numeroPartido: json['numero_partido'] as int,
      equipoLocalId: json['equipo_local_id'] as int?,
      equipoVisitId: json['equipo_visit_id'] as int?,
      equipoLocal: local,
      equipoVisit: visit,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      fechaCierrePredicciones:
          DateTime.parse(json['fecha_cierre_predicciones'] as String),
      ciudad: json['ciudad'] as String?,
      estadio: json['estadio'] as String?,
      pais: json['pais'] as String?,
      estado: EstadoPartido.fromString(json['estado'] as String),
      golesLocal: json['goles_local'] as int?,
      golesVisit: json['goles_visit'] as int?,
      resultado: json['resultado'] as String?,
      multiplicador: (json['multiplicador'] as num).toDouble(),
      ordenEnQuiniela: json['orden_en_quiniela'] as int?,
    );
  }

  /// Marcador formateado: "2 - 1" o "TBD" si no hay goles
  String get marcador {
    if (golesLocal == null || golesVisit == null) return 'TBD';
    return '$golesLocal - $golesVisit';
  }

  /// Si tenemos ambos equipos definidos
  bool get tieneEquiposDefinidos => equipoLocal != null && equipoVisit != null;

  /// Días restantes para el partido
  int get diasParaPartido {
    final ahora = DateTime.now();
    if (fechaHora.isBefore(ahora)) return 0;
    return fechaHora.difference(ahora).inDays;
  }

  /// Hora formateada (ej: "14:00")
  String get horaFormateada {
    final local = fechaHora.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  String toString() {
    return 'Partido($numeroPartido: ${equipoLocal?.codigo} vs ${equipoVisit?.codigo})';
  }
}