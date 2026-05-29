/// Modelo Inscripcion - matchea tabla `inscripciones` en Supabase
///
/// L41: Verificado contra information_schema 28 may 2026
///
/// Constraints clave:
/// - PK: id (bigint)
/// - FK CASCADE: user_id → profiles(id), quiniela_id → quinielas(id)
/// - UNIQUE (user_id, quiniela_id) → un user solo se inscribe 1 vez por quiniela
///
/// RLS:
/// - INSERT: WITH CHECK (auth.uid() = user_id)
/// - SELECT/UPDATE: USING (user_id = auth.uid())
///
/// Cancelación = soft-delete (activa=false + cancelled_at=now())
class Inscripcion {
  final int id;
  final String userId;
  final int quinielaId;
  final DateTime fechaInscripcion;
  final double puntosTotales;
  final int totalPredicciones;
  final int totalExactos;
  final int totalCerca;
  final int totalResultado;
  final int totalCasi;
  final int totalGoleadores;
  final bool activa;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Inscripcion({
    required this.id,
    required this.userId,
    required this.quinielaId,
    required this.fechaInscripcion,
    required this.puntosTotales,
    required this.totalPredicciones,
    required this.totalExactos,
    required this.totalCerca,
    required this.totalResultado,
    required this.totalCasi,
    required this.totalGoleadores,
    required this.activa,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialización desde JSON de Supabase
  factory Inscripcion.fromJson(Map<String, dynamic> json) {
    return Inscripcion(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      quinielaId: json['quiniela_id'] as int,
      fechaInscripcion: DateTime.parse(json['fecha_inscripcion'] as String),
      puntosTotales: (json['puntos_totales'] as num).toDouble(),
      totalPredicciones: (json['total_predicciones'] as int?) ?? 0,
      totalExactos: (json['total_exactos'] as int?) ?? 0,
      totalCerca: (json['total_cerca'] as int?) ?? 0,
      totalResultado: (json['total_resultado'] as int?) ?? 0,
      totalCasi: (json['total_casi'] as int?) ?? 0,
      totalGoleadores: (json['total_goleadores'] as int?) ?? 0,
      activa: (json['activa'] as bool?) ?? true,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Si la inscripción está vigente (activa y no cancelada)
  bool get estaVigente => activa && cancelledAt == null;

  @override
  String toString() {
    return 'Inscripcion(id: $id, quinielaId: $quinielaId, activa: $activa)';
  }
}