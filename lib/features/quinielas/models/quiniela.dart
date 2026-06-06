/// Modelo Quiniela - matchea tabla `quinielas` en Supabase
///
/// L41: Verificado contra information_schema 22 may 2026
///      Getters Midnight Stadium agregados 30 may 2026
///
/// Enums confirmados:
/// - estado_quiniela: {borrador, inscripcion, activa, finalizada, cancelada}
/// - tipo_quiniela: {oficial_progana, privada_promotor}
library;

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

  // ===========================================================================
  // GETTERS DE NEGOCIO (existentes Sprint 1)
  // ===========================================================================

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

  // ===========================================================================
  // GETTERS MIDNIGHT STADIUM (agregados 30 may 2026)
  // ===========================================================================

  /// Número de quiniela con padding "01", "02", ..., "09"
  String get numeroDisplay => numeroOrden.toString().padLeft(2, '0');

  /// Rango de fechas display "11-15 JUN" o "26 JUN" si es 1 día
  String get rangoDisplay {
    const meses = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];

    final diaInicio = fechaPrimerPartido.day;
    final diaFin = fechaUltimoPartido.day;
    final mesInicio = meses[fechaPrimerPartido.month];
    final mesFin = meses[fechaUltimoPartido.month];

    // Mismo día
    if (fechaPrimerPartido.year == fechaUltimoPartido.year &&
        fechaPrimerPartido.month == fechaUltimoPartido.month &&
        diaInicio == diaFin) {
      return '$diaInicio $mesInicio';
    }

    // Mismo mes
    if (fechaPrimerPartido.year == fechaUltimoPartido.year &&
        fechaPrimerPartido.month == fechaUltimoPartido.month) {
      return '$diaInicio-$diaFin $mesInicio';
    }

    // Meses diferentes
    return '$diaInicio $mesInicio - $diaFin $mesFin';
  }

  /// True si la quiniela está corriendo AHORA (estado activa + dentro de fechas)
  bool get estaActivaAhora {
    if (estado != EstadoQuiniela.activa) return false;
    final ahora = DateTime.now();
    return ahora.isAfter(fechaPrimerPartido) &&
           ahora.isBefore(fechaUltimoPartido.add(const Duration(days: 1)));
  }

  /// True si la quiniela aún no inicia (fecha primer partido en futuro)
  bool get esPendiente {
    final ahora = DateTime.now();
    return fechaPrimerPartido.isAfter(ahora);
  }

  /// True si la quiniela ya terminó
  bool get yaTermino {
    if (estado == EstadoQuiniela.finalizada) return true;
    final ahora = DateTime.now();
    return ahora.isAfter(fechaUltimoPartido.add(const Duration(days: 1)));
  }

  @override
  String toString() {
    return 'Quiniela(id: $id, nombre: $nombre, estado: ${estado.name})';
  }
}