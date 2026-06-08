// =============================================================================
// PROGANA Fantasy — RankingRepository
// =============================================================================
//
// L41 COMPLIANT (8 jun 2026 - Día 10 PM):
//   ✓ Queries verificadas contra matview rankings_general (8 jun 2026)
//   ✓ Queries verificadas contra matview rankings_quiniela (8 jun 2026)
//   ✓ Error handling defensive con PostgrestException
//   ✓ Soporta: ranking general acumulado + ranking por quiniela
//
// Backend:
// - rankings_general: matview con todos los users, posicion pre-calculada
// - rankings_quiniela: matview con quiniela_id (filtro requerido)
// - Refresh automático: trigger on_partido_finalizado → refresh_rankings()
//
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_entry.dart';

class RankingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // RANKING GENERAL (acumulado todas las quinielas)
  // ===========================================================================

  /// Obtiene el ranking general acumulado (top N).
  /// Default: top 100 (suficiente para podio + lista 4-100 + scroll).
  ///
  /// Returns: lista ordenada por posicion ASC (1, 2, 3, ...)
  Future<List<RankingEntry>> obtenerRankingGeneral({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('rankings_general')
          .select()
          .order('posicion', ascending: true)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => RankingEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar ranking general: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar ranking: $e');
    }
  }

  /// Obtiene la posición específica del usuario actual en ranking general.
  /// Útil para destacar "tú" en la lista (highlight).
  ///
  /// Returns: RankingEntry si user tiene puntos, null si no aparece en ranking
  Future<RankingEntry?> obtenerMiPosicionGeneral() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('rankings_general')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return RankingEntry.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar mi posición: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // ===========================================================================
  // RANKING POR QUINIELA (filtro por quiniela_id)
  // ===========================================================================

  /// Obtiene el ranking de una quiniela específica (top N).
  ///
  /// [quinielaId]: ID de la quiniela a consultar
  /// [limit]: max entries (default 100)
  Future<List<RankingEntry>> obtenerRankingQuiniela(
    int quinielaId, {
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('rankings_quiniela')
          .select()
          .eq('quiniela_id', quinielaId)
          .order('posicion', ascending: true)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => RankingEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
          'Error BD al cargar ranking quiniela $quinielaId: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene la posición específica del usuario actual en una quiniela.
  Future<RankingEntry?> obtenerMiPosicionQuiniela(int quinielaId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('rankings_quiniela')
          .select()
          .eq('quiniela_id', quinielaId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return RankingEntry.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar mi posición: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}