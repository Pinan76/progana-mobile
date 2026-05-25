import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiniela.dart';

/// Repositorio para gestionar quinielas vía Supabase
/// 
/// L41: Queries verificadas contra schema real 22 may 2026
/// Tabla quinielas: 29 columnas, RLS habilitado
class QuinielaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene TODAS las quinielas (sin filtrar por estado)
  /// 
  /// Útil para testing inicial. En producción usar [obtenerQuinielasAbiertas]
  /// 
  /// Returns: lista de quinielas ordenadas por numero_orden ascendente
  Future<List<Quiniela>> obtenerTodasQuinielas() async {
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