/// Modelo de una quiniela de clubes (Motor 2).
///
/// L41: campos verificados contra schema real de quinielas_liga (jun 2026).
class QuinielaLiga {
  final int id;
  final String nombre;
  final String? descripcion;
  final String codigoInvitacion;
  final int? capacidadMaxima;
  final String estado;
  final int totalInscritos;

  const QuinielaLiga({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.codigoInvitacion,
    this.capacidadMaxima,
    required this.estado,
    this.totalInscritos = 0,
  });

  factory QuinielaLiga.fromJson(Map<String, dynamic> json) {
    return QuinielaLiga(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      codigoInvitacion: (json['codigo_invitacion'] as String?) ?? '',
      capacidadMaxima: json['capacidad_maxima'] as int?,
      estado: (json['estado'] as String?) ?? 'borrador',
      totalInscritos: (json['total_inscritos'] as int?) ?? 0,
    );
  }

  /// Link que codifica el QR para que un participante se una.
  String get linkInvitacion => 'https://progana.mx/unirse/$codigoInvitacion';
}
