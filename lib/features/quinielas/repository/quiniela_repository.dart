import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiniela.dart';

/// Repositorio para gestionar quinielas vía Supabase
///
/// L41: Queries verificadas contra schema real 22 may 2026
/// Tabla quinielas: 29 columnas, RLS habilitado
///
/// PRE-MUNDIAL 8 JUN 2026 (Día 10):
///   ✓ State machine reactivo: cada listado de quinielas dispara
///     actualizar_estados_quinielas() RPC en BD (fire-and-forget)
///   ✓ Transiciones automáticas: borrador→inscripcion→activa→finalizada
///   ✓ Self-healing: si user no abre la app, no se actualiza
class QuinielaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // STATE MACHINE REACTIVO (Día 10 PM L41)
  // ===========================================================================

  /// Refresca estados de quinielas en BD (fire-and-forget).
  /// Ejecuta abrir → cerrar → finalizar según fechas configuradas.
  /// Silencioso ante errores (no rompe UI si BD no responde).
  Future<void> _refrescarEstadosQuinielas() async {
    try {
      await _supabase.rpc('actualizar_estados_quinielas');
    } catch (_) {
      // L41 fail-safe: silencioso para no romper UI
    }
  }

  // ===========================================================================
  // QUERIES (con refresh reactivo state machine)
  // ===========================================================================

  /// Obtiene TODAS las quinielas (sin filtrar por estado)
  ///
  /// Útil para testing inicial. En producción usar [obtenerQuinielasAbiertas]
  ///
  /// Returns: lista de quinielas ordenadas por numero_orden ascendente
  Future<List<Quiniela>> obtenerTodasQuinielas() async {
    // L41: Refrescar estados antes de cargar (fire-and-forget, no await)
    _refrescarEstadosQuinielas();

    try {
      final response = await _supabase
          .from('quinielas')
          .select()
          .order('numero_orden', ascending: true);
      final lista = (response as List<dynamic>)
          .map((json) => Quiniela.fromJson(json as Map<String, dynamic>))
          .toList();
      return lista;
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar quinielas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar quinielas: $e');
    }
  }

  /// Obtiene quinielas en estado 'inscripcion' o 'activa'
  /// (las que el usuario PUEDE ver/participar)
  Future<List<Quiniela>> obtenerQuinielasAbiertas() async {
    // L41: Refrescar estados antes de cargar (fire-and-forget, no await)
    _refrescarEstadosQuinielas();

    try {
      final response = await _supabase
          .from('quinielas')
          .select()
          .inFilter('estado', ['inscripcion', 'activa'])
          .order('numero_orden', ascending: true);
      final lista = (response as List<dynamic>)
          .map((json) => Quiniela.fromJson(json as Map<String, dynamic>))
          .toList();
      return lista;
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar quinielas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar quinielas: $e');
    }
  }

  /// Obtiene una quiniela específica por su ID
  Future<Quiniela?> obtenerQuinielaPorId(int id) async {
    try {
      final response = await _supabase
          .from('quinielas')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Quiniela.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar quiniela $id: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}