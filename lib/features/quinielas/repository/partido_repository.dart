import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partido.dart';

/// Repositorio para gestionar partidos vía Supabase
/// 
/// L41: Queries verificadas contra schema real 22 may 2026
/// 
/// Tablas relevantes:
///   - partidos (18 cols)
///   - partidos_quiniela (4 cols, relación N:M)
///   - equipos (16 cols)
class PartidoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los partidos asociados a una quiniela específica
  /// 
  /// Hace JOIN con:
  ///   - equipos (alias equipo_local) via equipo_local_id
  ///   - equipos (alias equipo_visit) via equipo_visit_id
  /// 
  /// Ordena por orden_en_quiniela (definido por el promotor/admin)
  /// 
  /// Returns: lista de partidos con equipos embebidos
  Future<List<Partido>> obtenerPartidosDeQuiniela(int quinielaId) async {
    try {
      // Step 1: Obtener IDs de partidos de esta quiniela + orden
      final relaciones = await _supabase
          .from('partidos_quiniela')
          .select('partido_id, orden_en_quiniela')
          .eq('quiniela_id', quinielaId)
          .order('orden_en_quiniela', ascending: true);

      if (relaciones.isEmpty) return [];

      // Step 2: Extraer IDs y crear mapa de orden
      final ids = <int>[];
      final mapaOrden = <int, int>{};
      for (final rel in relaciones) {
        final partidoId = rel['partido_id'] as int;
        final orden = rel['orden_en_quiniela'] as int;
        ids.add(partidoId);
        mapaOrden[partidoId] = orden;
      }

      // Step 3: Obtener partidos con equipos embebidos
      // Sintaxis Supabase para JOIN: tabla_destino!fk_column(*)
      final response = await _supabase
          .from('partidos')
          .select('''
            *,
            equipo_local:equipos!partidos_equipo_local_id_fkey(*),
            equipo_visit:equipos!partidos_equipo_visit_id_fkey(*)
          ''')
          .inFilter('id', ids);

      // Step 4: Convertir a modelos Dart e inyectar orden
      final lista = (response as List<dynamic>).map((json) {
        final mapa = json as Map<String, dynamic>;
        // Inyectar orden_en_quiniela en el JSON
        mapa['orden_en_quiniela'] = mapaOrden[mapa['id']];
        return Partido.fromJson(mapa);
      }).toList();

      // Step 5: Ordenar por orden_en_quiniela
      lista.sort((a, b) {
        final ordenA = a.ordenEnQuiniela ?? 999;
        final ordenB = b.ordenEnQuiniela ?? 999;
        return ordenA.compareTo(ordenB);
      });

      return lista;
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar partidos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar partidos: $e');
    }
  }

  /// Obtiene un partido específico por su ID (con equipos)
  Future<Partido?> obtenerPartidoPorId(int id) async {
    try {
      final response = await _supabase
          .from('partidos')
          .select('''
            *,
            equipo_local:equipos!partidos_equipo_local_id_fkey(*),
            equipo_visit:equipos!partidos_equipo_visit_id_fkey(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Partido.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar partido $id: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}