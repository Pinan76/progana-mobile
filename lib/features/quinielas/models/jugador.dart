/// Modelo Jugador - matchea tabla `jugadores` en Supabase
///
/// L41: Verificado contra information_schema 4 jun 2026
/// Tabla poblada con 104 jugadores Grupo A (MEX, RSA, KOR, CZE) FIFA oficial
class Jugador {
  final int id;
  final int equipoId;                  // FK a equipos.id
  final String nombre;                  // "Raúl Jiménez", "Son Heung-min", etc.
  final int? numeroJersey;              // Dorsal (null si no se conoce)
  final String? posicion;               // 'POR' | 'DEF' | 'MED' | 'DEL'
  final int golesCarrera;               // Goles internacionales históricos
  final int golesMundial;               // Goles en este Mundial (0 hasta arrancar)
  final int asistenciasMundial;         // Asistencias en este Mundial
  final bool activo;                    // Activo en el roster

  const Jugador({
    required this.id,
    required this.equipoId,
    required this.nombre,
    this.numeroJersey,
    this.posicion,
    required this.golesCarrera,
    required this.golesMundial,
    required this.asistenciasMundial,
    required this.activo,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      id: json['id'] as int,
      equipoId: json['equipo_id'] as int,
      nombre: json['nombre'] as String,
      numeroJersey: json['numero_jersey'] as int?,
      posicion: json['posicion'] as String?,
      golesCarrera: (json['goles_carrera'] as int?) ?? 0,
      golesMundial: (json['goles_mundial'] as int?) ?? 0,
      asistenciasMundial: (json['asistencias_mundial'] as int?) ?? 0,
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  /// Posición en español completo (display UI)
  String get posicionDisplay {
    switch (posicion) {
      case 'POR':
        return 'Portero';
      case 'DEF':
        return 'Defensa';
      case 'MED':
        return 'Mediocampista';
      case 'DEL':
        return 'Delantero';
      default:
        return '—';
    }
  }

  /// Emoji por posición (UI compact)
  String get emojiPosicion {
    switch (posicion) {
      case 'POR':
        return '🥅';
      case 'DEF':
        return '🛡️';
      case 'MED':
        return '⚙️';
      case 'DEL':
        return '⚽';
      default:
        return '👤';
    }
  }

  /// Es jugador estrella (goles_carrera >= 10) - para destacar en UI
  bool get esEstrella => golesCarrera >= 10;

  /// Es máxima estrella (goles_carrera >= 30) - para destacar EXTRA
  bool get esMaximaEstrella => golesCarrera >= 30;

  /// Nombre + posición display ("Raúl Jiménez · Delantero")
  String get nombreConPosicion {
    if (posicion == null) return nombre;
    return '$nombre · $posicionDisplay';
  }

  @override
  String toString() =>
      'Jugador($nombre - $posicionDisplay - ${golesCarrera}g)';
}