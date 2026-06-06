// =============================================================================
// PROGANA Fantasy — JugadorRepository
// =============================================================================
//
// L41 COMPLIANT (4 jun 2026 - Día 9 PM):
//   ✓ Tabla 'jugadores' verificada en BD (11 columnas, 104 jugadores Grupo A)
//   ✓ Métodos read-only (frontend no escribe jugadores, son seed-data)
//   ✓ Filtros: activo=true por defecto (excluye jugadores retirados)
//   ✓ Ordenamiento: posición (POR/DEF/MED/DEL) + goles_carrera DESC
//
// MÉTODOS:
//   - obtenerJugadoresDelPartido({local, visit}): Future<({local, visit})>
//   - obtenerJugadorPorId(id): Future<Jugador?>
//
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jugador.dart';

class JugadorRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // OBTENER JUGADORES DE LOS 2 EQUIPOS DEL PARTIDO
  // ===========================================================================

  /// Obtiene los jugadores activos de los 2 equipos que juegan un partido.
  /// Retorna un record con (local, visit) como listas separadas, ordenadas
  /// por posición (POR/DEF/MED/DEL) + goles_carrera DESC (estrellas primero).
  ///
  /// Usado por PredictMarcadorScreen para el selector de goleador (Plus/Pro).
  Future<({List<Jugador> local, List<Jugador> visit})>
      obtenerJugadoresDelPartido({
    required int equipoLocalId,
    required int equipoVisitId,
  }) async {
    try {
      // Query única para ambos equipos (más eficiente que 2 queries)
      final response = await _supabase
          .from('jugadores')
          .select()
          .inFilter('equipo_id', [equipoLocalId, equipoVisitId])
          .eq('activo', true);

      final todos = (response as List)
          .map((row) => Jugador.fromJson(row as Map<String, dynamic>))
          .toList();

      // Separar por equipo
      final local = todos.where((j) => j.equipoId == equipoLocalId).toList();
      final visit = todos.where((j) => j.equipoId == equipoVisitId).toList();

      // Ordenar cada lista: por posición + goles DESC
      _ordenarPorPosicionYGoles(local);
      _ordenarPorPosicionYGoles(visit);

      return (local: local, visit: visit);
    } catch (e) {
      throw JugadorException(
        'Error al cargar jugadores: ${e.toString()}',
      );
    }
  }

  // ===========================================================================
  // OBTENER JUGADOR POR ID (para mostrar nombre en predicción guardada)
  // ===========================================================================

  Future<Jugador?> obtenerJugadorPorId(int id) async {
    try {
      final response = await _supabase
          .from('jugadores')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Jugador.fromJson(response);
    } catch (e) {
      throw JugadorException(
        'Error al cargar jugador: ${e.toString()}',
      );
    }
  }

  // ===========================================================================
  // HELPERS PRIVADOS
  // ===========================================================================

  /// Ordena lista in-place: POR → DEF → MED → DEL, luego goles_carrera DESC
  void _ordenarPorPosicionYGoles(List<Jugador> lista) {
    const orden = {'POR': 0, 'DEF': 1, 'MED': 2, 'DEL': 3};
    lista.sort((a, b) {
      final ordenA = orden[a.posicion] ?? 99;
      final ordenB = orden[b.posicion] ?? 99;
      if (ordenA != ordenB) return ordenA.compareTo(ordenB);
      // Misma posición: estrellas primero (goles DESC)
      return b.golesCarrera.compareTo(a.golesCarrera);
    });
  }
}

/// Excepción específica al cargar jugadores
class JugadorException implements Exception {
  final String message;
  const JugadorException(this.message);

  @override
  String toString() => message;
}