// =============================================================================
// PROGANA Fantasy — OnboardingRepository
// =============================================================================
//
// L41 COMPLIANT (8 jun 2026 - Día 10 PM):
//   ✓ Manejo del flag profiles.onboarding_completed
//   ✓ Verificado contra schema BD (columna agregada hoy)
//   ✓ Error handling defensive con PostgrestException
//   ✓ Defensive: si user no autenticado, retorna false (no muestra onboarding)
//
// Operaciones:
// - debeVer(): true si user NO ha completado onboarding
// - marcarCompletado(): UPDATE profiles SET onboarding_completed=true
//
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verifica si el usuario actual debe ver el onboarding.
  /// 
  /// Retorna true SI:
  /// - Hay user autenticado
  /// - profiles.onboarding_completed = false (o NULL defensivo)
  /// 
  /// Retorna false SI:
  /// - No hay user (no aplica)
  /// - Ya completó onboarding
  /// - Error de BD (fail-safe, no bloquear UI)
  Future<bool> debeVerOnboarding() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;

      final completado = response['onboarding_completed'] as bool?;
      // Si NULL (defensive) o false → mostrar onboarding
      return completado != true;
    } on PostgrestException catch (_) {
      // L41 fail-safe: si falla BD, no mostrar onboarding (no bloquear flow)
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Marca el onboarding como completado para el usuario actual.
  /// Idempotente: si ya está marcado, no hace nada.
  /// 
  /// Returns: true si UPDATE exitoso, false si falla.
  Future<bool> marcarCompletado() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('profiles').update({
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      return true;
    } on PostgrestException catch (e) {
      // L41: log pero no crash si UPDATE falla
      // (user puede re-completar al cerrar app y volver)
      _logError('marcarCompletado PostgrestException: ${e.message}');
      return false;
    } catch (e) {
      _logError('marcarCompletado error: $e');
      return false;
    }
  }

  // ===========================================================================
  // PRIVATE
  // ===========================================================================

  void _logError(String message) {
    // En producción usar logger formal; por ahora print silencioso
    assert(() {
      // ignore: avoid_print
      print('[OnboardingRepository] $message');
      return true;
    }());
  }
}