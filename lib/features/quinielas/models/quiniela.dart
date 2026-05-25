/// Modelo Quiniela - matchea tabla `quinielas` en Supabase
/// 
/// L41: Verificado contra information_schema 22 may 2026
/// 
/// Enums confirmados:
/// - estado_quiniela: {borrador, inscripcion, activa, finalizada, cancelada}
/// - tipo_quiniela: {oficial_progana, privada_promotor}

/// Estado del ciclo de vida de una quiniela
enum EstadoQuiniela {
  borrador,
  inscripcion,
  activa,
  finalizada,
  cancelada;

  /// Convierte string de Postgres a enum Dart
  static EstadoQuiniela fromString(String value) {
    return EstadoQuiniela.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoQuiniela.borrador,
    );
  }

  /// Etiqueta legible en español para mostrar al usuario
  String get etiqueta {
    switch (this) {
      case EstadoQuiniela.borrador:
        return 'Próximamente';
      case EstadoQuiniela.inscripcion:
        return 'Inscripciones Abiertas';
      case EstadoQuiniela.activa:
        return 'En Juego';
      case EstadoQuiniela.finalizada:
        return 'Finalizada';
      case EstadoQuiniela.cancelada:
        return 'Cancelada';
    }
  }

  /// Si el usuario puede inscribirse
  bool get permiteInscripcion => this == EstadoQuiniela.inscripcion;
}

/// Tipo de quiniela (oficial PROGANA vs privada promotor)
enum TipoQuiniela {
  oficialProgana,
  privadaPromotor;

  /// Convierte string de Postgres a enum Dart
  /// Postgres usa snake_case: 'oficial_progana', 'privada_promotor'
  /// Dart usa camelCase: oficialProgana, privadaPromotor
  static TipoQuiniela fromString(String value) {
    switch (value) {
      case 'oficial_progana':
        return TipoQuiniela.oficialProgana;
      case 'privada_promotor':
        return TipoQuiniela.privadaPromotor;
      default:
        return TipoQuiniela.oficialProgana;
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoQuiniela.oficialProgana:
        return 'Oficial PROGANA';
      case TipoQuiniela.privadaPromotor:
        return 'Privada';
    }
  }
}

/// Modelo principal de una quiniela
class Quiniela {
  final int id;
  final String nombre;
  final String slug;
  final int numeroOrden;
  final String? descripcion;
  final bool esAcumulado;
  final DateTime aperturaInscripcion;
  final DateTime? cierreInscripcion;
  final DateTime fechaPrimerPartido;
  final DateTime fechaUltimoPartido;
  final EstadoQuiniela estado;
  final TipoQuiniela tipoQuiniela;
  final String? colorPrimario;
  final String? imagenUrl;
  final int totalInscritos;
  final int totalPredicciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quiniela({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.numeroOrden,
    this.descripcion,
    required this.esAcumulado,
    required this.aperturaInscripcion,
    this.cierreInscripcion,
    required this.fechaPrimerPartido,
    required this.fechaUltimoPartido,
    required this.estado,
    required this.tipoQuiniela,
    this.colorPrimario,
    this.imagenUrl,
    required this.totalInscritos,
    required this.totalPredicciones,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialización desde JSON de Supabase
  factory Quiniela.fromJson(Map<String, dynamic> json) {
    return Quiniela(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      slug: json['slug'] as String,
      numeroOrden: json['numero_orden'] as int,
      descripcion: json['descripcion'] as String?,
      esAcumulado: (json['es_acumulado'] as bool?) ?? false,
      aperturaInscripcion: DateTime.parse(json['apertura_inscripcion'] as String),
      cierreInscripcion: json['cierre_inscripcion'] != null
          ? DateTime.parse(json['cierre_inscripcion'] as String)
          : null,
      fechaPrimerPartido: DateTime.parse(json['fecha_primer_partido'] as String),
      fechaUltimoPartido: DateTime.parse(json['fecha_ultimo_partido'] as String),
      estado: EstadoQuiniela.fromString(json['estado'] as String),
      tipoQuiniela: TipoQuiniela.fromString(json['tipo_quiniela'] as String),
      colorPrimario: json['color_primario'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      totalInscritos: (json['total_inscritos'] as int?) ?? 0,
      totalPredicciones: (json['total_predicciones'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Días restantes para que cierren inscripciones
  int? get diasParaCierre {
    if (cierreInscripcion == null) return null;
    final ahora = DateTime.now();
    if (cierreInscripcion!.isBefore(ahora)) return 0;
    return cierreInscripcion!.difference(ahora).inDays;
  }

  /// Días restantes para que arranque la quiniela
  int? get diasParaInicio {
    final ahora = DateTime.now();
    if (fechaPrimerPartido.isBefore(ahora)) return 0;
    return fechaPrimerPartido.difference(ahora).inDays;
  }

  @override
  String toString() {
    return 'Quiniela(id: $id, nombre: $nombre, estado: ${estado.name})';
  }
}