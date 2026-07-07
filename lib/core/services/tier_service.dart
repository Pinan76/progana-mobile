// =============================================================================
// PROGANA Fantasy — TierService
// =============================================================================
// Fuente ÚNICA del tier del usuario en la app: profiles.tier.
// Cachea el valor una vez cargado (usa force:true tras un upgrade).
// Failsafe = 'free' (seguro por defecto): si no se puede determinar el tier,
// se trata como free → NO se otorga Predict ni features premium.
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class TierService {
  TierService._();
  static final TierService instance = TierService._();

  final SupabaseClient _sb = Supabase.instance.client;
  String _tier = 'free';
  bool _cargado = false;

  String get tier => _tier;
  bool get cargado => _cargado;

  bool get isFree => _tier == 'free';
  bool get isPlus => _tier == 'plus';
  bool get isPro => _tier == 'pro';

  /// True si el usuario puede ver PROGANA Predict (plus o pro). Free NUNCA.
  bool get puedePredict => _tier == 'plus' || _tier == 'pro';

  /// True si puede CREAR quinielas privadas (solo pro).
  bool get puedeCrearQuinielas => _tier == 'pro';

  /// Carga el tier desde profiles. Cachea; usa force:true tras un upgrade/pago.
  Future<void> cargar({bool force = false}) async {
    if (_cargado && !force) return;
    final user = _sb.auth.currentUser;
    if (user == null) {
      _tier = 'free';
      _cargado = true;
      return;
    }
    try {
      final row = await _sb
          .from('profiles')
          .select('tier')
          .eq('id', user.id)
          .maybeSingle();
      _tier = (row?['tier'] as String?) ?? 'free';
    } catch (_) {
      _tier = 'free'; // failsafe: ante la duda, free (no otorgar premium)
    }
    _cargado = true;
  }

  /// Limpia el caché (llamar al cerrar sesión).
  void reset() {
    _tier = 'free';
    _cargado = false;
  }
}
