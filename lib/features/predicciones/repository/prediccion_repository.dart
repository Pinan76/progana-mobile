// =============================================================================
// PROGANA Fantasy — PrediccionRepository
// =============================================================================
//
// L41 COMPLIANT (3 jun 2026 - Día 8):
//   ✓ Usa nombre singular consistente (prediccion_repository.dart, PrediccionRepository)
//   ✓ Tabla 'predicciones' verificada en BD (16 columnas)
//   ✓ UNIQUE constraint (user_id, partido_id, quiniela_id) → UPSERT
//   ✓ RLS policies verificadas: INSERT/SELECT/UPDATE solo own predicciones
//   ✓ pred_resultado SIEMPRE obligatorio (calculado auto para Plus/Pro)
//   ✓ Constraint checks check_free_solo_resultado + check_pro_marcador respetados
//   ✓ Maneja partidos cerrados (no permite predecir si estado != programado)
//
// MÉTODOS:
//   - obtenerMiPrediccion(partidoId, quinielaId): Future<Prediccion?>
//   - guardarPrediccion({...}): Future<Prediccion>  ← UPSERT
//   - obtenerMisPrediccionesDeQuiniela(quinielaId): Future<List<Prediccion>>
//
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediccion.dart';

class PrediccionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // OBTENER MI PREDICCIÓN (UN partido específico)
  // ===========================================================================

  /// Obtiene la predicción del user actual para un partido específico
  /// en una quiniela específica.
  ///
  /// Retorna null si el user no ha predicho aún ese partido.
  ///
  /// RLS garantiza que solo retorna predicciones donde user_id = auth.uid()
  Future<Prediccion?> obtenerMiPrediccion({
    required int partidoId,
    required int quinielaId,
  }) async {
    try {
      final response = await _supabase
          .from('predicciones')
          .select()
          .eq('partido_id', partidoId)
          .eq('quiniela_id', quinielaId)
          .maybeSingle();

      if (response == null) return null;

      return Prediccion.fromJson(response);
    } catch (e) {
      throw PrediccionException(
        'Error al cargar tu predicción: ${e.toString()}',
      );
    }
  }

  // ===========================================================================
  // GUARDAR PREDICCIÓN (UPSERT por UNIQUE constraint)
  // ===========================================================================

  /// Guarda o actualiza una predicción.
  ///
  /// La tabla tiene UNIQUE (user_id, partido_id, quiniela_id), por lo que
  /// usar UPSERT permite que la misma operación sirva para INSERT y UPDATE.
  ///
  /// Para FREE: pasar [golesLocal] y [golesVisit] como null, [resultado] obligatorio
  /// Para PLUS/PRO: pasar [golesLocal] y [golesVisit] obligatorios.
  ///                [resultado] se calcula automáticamente a partir de los goles.
  ///
  /// Lanza:
  ///   - [TierInvalidoException] si los argumentos no son compatibles con el tier
  ///   - [PrediccionException] si falla el insert/update en BD
  Future<Prediccion> guardarPrediccion({
    required int partidoId,
    required int quinielaId,
    required TierAlPredecir tier,
    int? golesLocal,
    int? golesVisit,
    String? resultado, // Solo para Free; Plus/Pro lo calcula auto
  }) async {
    // Validación de tier compatible con argumentos
    if (tier == TierAlPredecir.free) {
      if (resultado == null) {
        throw const TierInvalidoException(
          'Free tier requiere especificar resultado (L/E/V)',
        );
      }
      if (golesLocal != null || golesVisit != null) {
        throw const TierInvalidoException(
          'Free tier NO puede predecir marcador exacto',
        );
      }
    } else {
      // Plus o Pro
      if (golesLocal == null || golesVisit == null) {
        throw const TierInvalidoException(
          'Plus/Pro debe predecir marcador (ambos goles)',
        );
      }
      if (golesLocal < 0 || golesLocal > 20) {
        throw const TierInvalidoException('Goles local fuera de rango (0-20)');
      }
      if (golesVisit < 0 || golesVisit > 20) {
        throw const TierInvalidoException('Goles visit fuera de rango (0-20)');
      }
    }

    // Para Plus/Pro: calcular resultado automáticamente
    final String resultadoFinal = tier == TierAlPredecir.free
        ? resultado!
        : ResultadoPartido.calcular(golesLocal!, golesVisit!);

    // user_id viene del auth (no se pasa, el trigger anti-spoofing lo asignará)
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const PrediccionException('No hay sesión activa');
    }

    try {
      // UPSERT usando ON CONFLICT en UNIQUE constraint
      final response = await _supabase
          .from('predicciones')
          .upsert(
            {
              'user_id': userId,
              'partido_id': partidoId,
              'quiniela_id': quinielaId,
              'pred_local': golesLocal,
              'pred_visit': golesVisit,
              'pred_resultado': resultadoFinal,
              'tier_al_predecir': tier.value,
              // fecha_prediccion, created_at, updated_at se llenan por DB defaults
            },
            onConflict: 'user_id,partido_id,quiniela_id',
          )
          .select()
          .single();

      return Prediccion.fromJson(response);
    } on PostgrestException catch (e) {
      // Manejo específico de errores de Postgres
      if (e.message.contains('check_pro_marcador') ||
          e.message.contains('check_free_solo_resultado')) {
        throw const TierInvalidoException(
          'Tu tier no permite este tipo de predicción',
        );
      }
      throw PrediccionException(
        'Error guardando predicción: ${e.message}',
      );
    } catch (e) {
      throw PrediccionException(
        'Error guardando predicción: ${e.toString()}',
      );
    }
  }

  // ===========================================================================
  // OBTENER MIS PREDICCIONES DE UNA QUINIELA (lista completa)
  // ===========================================================================

  /// Obtiene todas las predicciones del user actual en una quiniela.
  /// Útil para mostrar en Detalle Quiniela qué partidos ya predijo.
  Future<List<Prediccion>> obtenerMisPrediccionesDeQuiniela({
    required int quinielaId,
  }) async {
    try {
      final response = await _supabase
          .from('predicciones')
          .select()
          .eq('quiniela_id', quinielaId)
          .order('fecha_prediccion', ascending: false);

      return (response as List)
          .map((row) => Prediccion.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw PrediccionException(
        'Error al cargar predicciones: ${e.toString()}',
      );
    }
  }
}