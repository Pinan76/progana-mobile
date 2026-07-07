// =============================================================================
// PROGANA Fantasy — PredictRepository
// =============================================================================
//
// L41 COMPLIANT (16 jun 2026):
//   ✓ HTTP client a PROGANA Predict API (Render deployed)
//   ✓ Endpoint /predictions: trae TODOS los partidos del Mundial + cuotas
//   ✓ Caché en memoria (no llamar al backend por cada PredictCard)
//   ✓ Filtro por equipos (home + away) vía canonical match
//   ✓ FAILSAFE STRICT: si API falla, retorna null (app sigue funcionando)
//   ✓ Singleton para compartir caché entre PredictCards
//
// CANDADO SERVER-SIDE (jul 2026):
//   ✓ Las llamadas pasan por la Edge Function 'predict-gate' (no directo a Render)
//   ✓ La función valida profiles.tier: Free → 403 → failsafe → null
//   ✓ functions.invoke() agrega el JWT del usuario + apikey automáticamente
//   ✓ isHealthy() sigue pegando directo a Render (health no está gateado)
//
// COMPORTAMIENTO L41 BRUTAL:
//   - Timeout → null (UI muestra "IA no disponible")
//   - 403 (free) / 401 (sin sesión) → null (failsafe silencioso)
//   - Network error / JSON malformado / partido no encontrado → null
//
// NUNCA lanza excepción al caller. NUNCA bloquea la app.
// =============================================================================
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/predict_config.dart';
import '../models/prediction_result.dart';

class PredictRepository {
  // Singleton para compartir caché entre todas las PredictCards
  static final PredictRepository _instance = PredictRepository._internal();
  factory PredictRepository() => _instance;
  PredictRepository._internal();

  final http.Client _client = http.Client();

  // Caché en memoria de la lista de predicciones de liga
  List<PredictionResult>? _cachedPredictions;
  DateTime? _cacheTimestamp;
  String? _cacheKey; // "league:season" para invalidar si cambia

  // Evita llamadas concurrentes duplicadas (varias PredictCards al mismo tiempo)
  Future<List<PredictionResult>?>? _inFlightRequest;

  /// Cierra el client HTTP
  void dispose() {
    _client.close();
  }

  // ===========================================================================
  // MÉTODO PRINCIPAL — Obtener predicción de UN partido (vía lista cacheada)
  // ===========================================================================
  Future<PredictionResult?> obtenerPrediccion({
    required String home,
    required String away,
    String? league,
    int? season,
  }) async {
    if (!PredictConfig.enabled) {
      _logSilent('Predict deshabilitado por config');
      return null;
    }
    if (home.isEmpty || away.isEmpty) {
      _logSilent('home o away vacíos');
      return null;
    }
    final lista = await _obtenerListaPredicciones(
      league: league ?? PredictConfig.defaultLeague,
      season: season ?? PredictConfig.defaultSeason,
    );
    if (lista == null || lista.isEmpty) {
      _logSilent('Lista de predicciones vacía o null');
      return null;
    }
    final match = _buscarPartido(lista, home, away);
    if (match == null) {
      _logSilent('Partido $home vs $away no encontrado en la lista');
    }
    return match;
  }

  // ===========================================================================
  // OBTENER LISTA DE PREDICCIONES (con caché + dedupe de requests)
  // ===========================================================================
  Future<List<PredictionResult>?> _obtenerListaPredicciones({
    required String league,
    required int season,
  }) async {
    final key = '$league:$season';
    if (_cachedPredictions != null &&
        _cacheTimestamp != null &&
        _cacheKey == key &&
        DateTime.now().difference(_cacheTimestamp!) < PredictConfig.cacheTtl) {
      _logSilent('Caché HIT ($key, ${_cachedPredictions!.length} partidos)');
      return _cachedPredictions;
    }
    if (_inFlightRequest != null && _cacheKey == key) {
      _logSilent('Request en vuelo, esperando...');
      return _inFlightRequest;
    }
    _cacheKey = key;
    _inFlightRequest = _fetchPredictions(league: league, season: season);
    try {
      final result = await _inFlightRequest;
      if (result != null) {
        _cachedPredictions = result;
        _cacheTimestamp = DateTime.now();
      }
      return result;
    } finally {
      _inFlightRequest = null;
    }
  }

  // ===========================================================================
  // FETCH — vía Edge Function 'predict-gate' (candado de tier server-side)
  // ===========================================================================
  Future<List<PredictionResult>?> _fetchPredictions({
    required String league,
    required int season,
  }) async {
    try {
      // 🔐 invoke() agrega solo el JWT del usuario + apikey → auth automática.
      // La función valida el tier: Free → 403 (lo tomamos como failsafe → null).
      _logSilent('invoke predict-gate (league=$league, season=$season)');
      final res = await Supabase.instance.client.functions
          .invoke(
            'predict-gate',
            method: HttpMethod.get,
            queryParameters: {
              'endpoint': 'predictions',
              'league': league,
              'season': season.toString(),
            },
          )
          .timeout(PredictConfig.timeout);

      if (res.status != 200) {
        _logSilent('Status ${res.status}: ${res.data}');
        return null; // 403 (free), 401 (sin sesión), etc. → failsafe
      }

      final raw = res.data;
      final Map<String, dynamic> decoded = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);

      final preds = decoded['predictions'];
      if (preds is! List) {
        _logSilent('Campo predictions no es lista');
        return null;
      }

      final result = <PredictionResult>[];
      for (final item in preds) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(PredictionResult.fromJson(item));
          } catch (e) {
            _logSilent('Error parseando item: $e');
          }
        }
      }
      _logSilent('Lista parseada: ${result.length} partidos');
      return result;
    } on FunctionException catch (e) {
      // invoke lanza esto en respuestas no-2xx (p.ej. 403 free, 401 sin sesión)
      _logSilent('FunctionException ${e.status}: ${e.details}');
      return null;
    } on TimeoutException {
      _logSilent('Timeout ${PredictConfig.timeout.inSeconds}s');
      return null;
    } on FormatException catch (e) {
      _logSilent('FormatException JSON: ${e.message}');
      return null;
    } catch (e) {
      _logSilent('Error inesperado: $e');
      return null;
    }
  }

  // ===========================================================================
  // BÚSQUEDA — Filtrar partido por equipos
  // ===========================================================================
  PredictionResult? _buscarPartido(
    List<PredictionResult> lista,
    String home,
    String away,
  ) {
    final h = _normalizar(home);
    final a = _normalizar(away);
    for (final pred in lista) {
      if (_normalizar(pred.home) == h && _normalizar(pred.away) == a) {
        return pred;
      }
    }
    for (final pred in lista) {
      if (_normalizar(pred.home) == a && _normalizar(pred.away) == h) {
        return pred;
      }
    }
    return null;
  }

  String _normalizar(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ===========================================================================
  // HEALTH CHECK (opcional, debug-only) — directo a Render (no gateado)
  // ===========================================================================
  Future<bool> isHealthy() async {
    if (!PredictConfig.enabled) return false;
    try {
      final uri = Uri.parse(
          '${PredictConfig.baseUrl}${PredictConfig.healthEndpoint}');
      final response = await _client.get(uri).timeout(PredictConfig.timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Limpia el caché manualmente (útil al cambiar de quiniela/competición)
  void limpiarCache() {
    _cachedPredictions = null;
    _cacheTimestamp = null;
    _cacheKey = null;
  }

  // ===========================================================================
  // PRIVATE — Logger silencioso (solo debug mode)
  // ===========================================================================
  void _logSilent(String message) {
    assert(() {
      // ignore: avoid_print
      print('[PredictRepository] $message');
      return true;
    }());
  }
}
