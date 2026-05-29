import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inscripcion.dart';

/// Repositorio para gestionar inscripciones vía Supabase
///
/// L41: Queries verificadas contra schema real 28 may 2026
///
/// Tabla inscripciones:
/// - 15 columnas, RLS habilitado
/// - UNIQUE (user_id, quiniela_id) previene duplicados
/// - Trigger aa_set_user_id_from_auth valida user_id contra auth.uid()
/// - Soft-delete via activa=false + cancelled_at
///
/// RLS Policies:
/// - INSERT: WITH CHECK (auth.uid() = user_id)
/// - SELECT/UPDATE: USING (user_id = auth.uid())
class InscripcionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Inscribe al usuario actual a una quiniela
  ///
  /// Retorna la Inscripcion creada
  ///
  /// Lanza:
  /// - [InscripcionDuplicadaException] si el usuario ya está inscrito (UNIQUE violation)
  /// - [Exception] en otros errores
  ///
  /// Nota L41: user_id se envía explícitamente; el trigger
  /// aa_set_user_id_from_auth valida que coincida con auth.uid()
  Future<Inscripcion> inscribirme(int quinielaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final response = await _supabase
          .from('inscripciones')
          .insert({
            'user_id': userId,
            'quiniela_id': quinielaId,
          })
          .select()
          .single();

      return Inscripcion.fromJson(response);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation (ya inscrito)
      if (e.code == '23505') {
        throw InscripcionDuplicadaException(
          'Ya estás inscrito en esta quiniela',
        );
      }
      throw Exception('Error BD al inscribirse: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al inscribirse: $e');
    }
  }

  /// Verifica si el usuario actual ya está inscrito (activamente) en una quiniela
  ///
  /// Returns:
  /// - Inscripcion si está inscrito y activa
  /// - null si no está inscrito o canceló
  Future<Inscripcion?> verificarInscripcion(int quinielaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('inscripciones')
          .select()
          .eq('user_id', userId)
          .eq('quiniela_id', quinielaId)
          .eq('activa', true)
          .maybeSingle();

      if (response == null) return null;

      return Inscripcion.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al verificar inscripción: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene todas las inscripciones activas del usuario actual
  ///
  /// Útil para pantalla "Mis Quinielas" (a implementar)
  Future<List<Inscripcion>> obtenerMisInscripciones() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('inscripciones')
          .select()
          .eq('user_id', userId)
          .eq('activa', true)
          .order('fecha_inscripcion', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Inscripcion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar inscripciones: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}

/// Excepción específica cuando el usuario intenta inscribirse 2 veces
class InscripcionDuplicadaException implements Exception {
  final String message;
  InscripcionDuplicadaException(this.message);

  @override
  String toString() => message;
}