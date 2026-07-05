import 'quiniela_liga.dart';

/// Una PARTICIPACIÓN del usuario en una quiniela de clubes.
/// Un usuario puede tener varias en la misma quiniela (Juan, Juan2, ...).
class MiQuinielaLiga {
  final int participacionId;
  final String nickname;
  final String miEstado; // invitado / confirmado_plus / activo
  final bool confirmada; // ¿ya bloqueó sus predicciones?
  final QuinielaLiga quiniela;

  MiQuinielaLiga({
    required this.participacionId,
    required this.nickname,
    required this.miEstado,
    required this.confirmada,
    required this.quiniela,
  });

  factory MiQuinielaLiga.fromJson(Map<String, dynamic> j) => MiQuinielaLiga(
        participacionId: (j['participacion_id'] as num).toInt(),
        nickname: (j['nickname'] as String?) ?? 'Jugador',
        miEstado: (j['mi_estado'] as String?) ?? 'invitado',
        confirmada: (j['confirmada'] as bool?) ?? false,
        quiniela: QuinielaLiga.fromJson(j),
      );

  bool get pendiente => miEstado == 'confirmado_plus';
  bool get activo => miEstado == 'activo';
}
