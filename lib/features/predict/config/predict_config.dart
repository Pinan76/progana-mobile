// =============================================================================
// PROGANA Fantasy — Predict Config
// =============================================================================
//
// L41 COMPLIANT (16 jun 2026):
//   ✓ Config centralizada para PROGANA Predict API
//   ✓ URL backend Render (servicio aislado)
//   ✓ Endpoint /predictions (liga EN VIVO con cuotas API-Football)
//   ✓ Timeouts agresivos (failsafe: si API lenta, app sigue)
//   ✓ Versioning incluido para tracking
//
// Backend: github.com/Pinan76/progana-predict
// Deploy: Render Free tier
//
// FAILSAFE L41:
//   - Si API caída → widget muestra mensaje silencioso
//   - Si API lenta (>timeout) → fallback gracioso
//   - Predicciones del user NO dependen de IA
//
// =============================================================================

library;

class PredictConfig {
  PredictConfig._();

  /// URL base del servicio PROGANA Predict desplegado en Render
  ///
  /// IMPORTANTE: Actualizar con la URL real tras el deploy en Render.
  static const String baseUrl = 'https://progana-predict.onrender.com';

  /// Endpoint para predicción individual (modelo solo o con cuotas manuales)
  static const String predictEndpoint = '/api/v1/predict';

  /// Endpoint para predicciones de liga EN VIVO (fixtures + cuotas API-Football)
  /// Devuelve TODOS los próximos partidos de la liga con caché TTL en backend.
  static const String predictionsEndpoint = '/api/v1/predictions';

  /// Endpoint para health check
  static const String healthEndpoint = '/health';

  /// Liga/competición por defecto para el Mundial 2026
  /// API-Football usa "worldcup" (league id 1 internamente).
  static const String defaultLeague = 'worldcup';

  /// Temporada del Mundial
  static const int defaultSeason = 2026;

  /// Timeout L41 strict: si API tarda más de esto, fallback gracioso
  ///
  /// Render Free tier puede tener cold starts (~30-50s el primer hit).
  /// Damos margen mayor a /predictions porque consulta API-Football.
  static const Duration timeout = Duration(seconds: 8);

  /// TTL del caché local en Flutter (evita llamar al backend por cada partido)
  /// El backend ya cachea, pero esto evita ida-vuelta innecesaria.
  static const Duration cacheTtl = Duration(minutes: 10);

  /// Versión del cliente para tracking
  static const String clientVersion = '1.1.0';

  /// Precisión histórica para badge (fallback si API no responde)
  /// Documentado en handoff Sección 3: ~59% al nivel del mercado
  static const double fallbackAccuracy = 0.59;

  /// Habilitar widget IA (toggle global)
  ///
  /// L41 strict: si en debug queremos desactivar, set false aquí.
  static const bool enabled = true;
}