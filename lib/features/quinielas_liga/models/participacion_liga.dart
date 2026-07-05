/// Un participante dentro de una quiniela de clubes (Motor 2).
///
/// Estados (enum estado_participacion en BD):
///   invitado · confirmado_plus · activo · rechazado · cancelado
class ParticipacionLiga {
  final int id;
  final String userId;
  final String nombre;
  final String? email;
  final String estado;

  ParticipacionLiga({
    required this.id,
    required this.userId,
    required this.nombre,
    this.email,
    required this.estado,
  });

  factory ParticipacionLiga.fromJson(Map<String, dynamic> j) {
    final n = (j['nombre'] as String?)?.trim();
    return ParticipacionLiga(
      id: j['id'] as int,
      userId: j['user_id'] as String,
      nombre: (n != null && n.isNotEmpty) ? n : 'Participante',
      email: j['email'] as String?,
      estado: j['estado'] as String,
    );
  }

  /// Espera confirmación del promotor.
  bool get pendiente => estado == 'confirmado_plus';
  bool get activo => estado == 'activo';
  bool get rechazado => estado == 'rechazado';
}
