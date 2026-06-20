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
// COMPORTAMIENTO L41 BRUTAL:
//   - Timeout → null (UI muestra "IA no disponible")
//   - Network error → null
//   - 404/500/503 → null
//   - JSON malformado → null
//   - Partido no encontrado en la lista → null
//   - Toggle off → null
//
// NUNCA lanza excepción al caller. NUNCA bloquea la app.
//
// ESTRATEGIA /predictions:
//   1. Primera PredictCard llama /predictions?league=worldcup&season=2026
//   2. Recibe lista de ~10 partidos próximos con cuotas
//   3. Cachea la lista (TTL 10 min)
//   4. Filtra el partido que coincida home + away
//   5. Siguientes PredictCards reusan el caché (cero llamadas extra)
//
// =============================================================================

library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Obtiene predicción IA para un partido específico del Mundial.
  ///
  /// Internamente: trae la lista completa de /predictions (cacheada) y filtra
  /// el partido que coincida con home + away.
  ///
  /// L41 FAILSAFE: retorna null si cualquier cosa falla.
  ///
  /// Parámetros:
  /// - [home]: nombre equipo local en inglés (ej. "Mexico")
  /// - [away]: nombre equipo visitante en inglés (ej. "Brazil")
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

    // 1. Obtener lista de predicciones (cacheada o fresca)
    final lista = await _obtenerListaPredicciones(
      league: league ?? PredictConfig.defaultLeague,
      season: season ?? PredictConfig.defaultSeason,
    );

    if (lista == null || lista.isEmpty) {
      _logSilent('Lista de predicciones vacía o null');
      return null;
    }

    // 2. Filtrar el partido que coincida home + away
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

    // Caché válido y misma key → reusar
    if (_cachedPredictions != null &&
        _cacheTimestamp != null &&
        _cacheKey == key &&
        DateTime.now().difference(_cacheTimestamp!) < PredictConfig.cacheTtl) {
      _logSilent('Caché HIT ($key, ${_cachedPredictions!.length} partidos)');
      return _cachedPredictions;
    }

    // Si ya hay un request en vuelo con la misma key, esperar ese
    if (_inFlightRequest != null && _cacheKey == key) {
      _logSilent('Request en vuelo, esperando...');
      return _inFlightRequest;
    }

    // Lanzar request nuevo
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
  // FETCH HTTP — /api/v1/predictions
  // ===========================================================================

  Future<List<PredictionResult>?> _fetchPredictions({
    required String league,
    required int season,
  }) async {
    try {
      final uri = Uri.parse(
        '${PredictConfig.baseUrl}${PredictConfig.predictionsEndpoint}',
      ).replace(queryParameters: {
        'league': league,
        'season': season.toString(),
      });

      _logSilent('GET $uri');

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'PROGANA-Fantasy/${PredictConfig.clientVersion} (Flutter)',
        },
      ).timeout(PredictConfig.timeout);

      if (response.statusCode != 200) {
        _logSilent('Status ${response.statusCode}: ${response.body}');
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _logSilent('JSON no es Map');
        return null;
      }

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
            // continuar con los demás
          }
        }
      }

      _logSilent('Lista parseada: ${result.length} partidos');
      return result;
    } on TimeoutException {
      _logSilent('Timeout ${PredictConfig.timeout.inSeconds}s');
      return null;
    } on http.ClientException catch (e) {
      _logSilent('ClientException: ${e.message}');
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

  /// Busca en la lista el partido que coincida home + away.
  ///
  /// Match flexible: compara normalizado (sin distinguir mayúsculas/espacios)
  /// para tolerar pequeñas diferencias de formato entre Supabase y el motor.
  PredictionResult? _buscarPartido(
    List<PredictionResult> lista,
    String home,
    String away,
  ) {
    final h = _normalizar(home);
    final a = _normalizar(away);

    for (final pred in lista) {
      final ph = _normalizar(pred.home);
      final pa = _normalizar(pred.away);
      // Match directo (mismo local/visitante)
      if (ph == h && pa == a) return pred;
    }

    // Match invertido (por si el motor tiene home/away al revés)
    for (final pred in lista) {
      final ph = _normalizar(pred.home);
      final pa = _normalizar(pred.away);
      if (ph == a && pa == h) return pred;
    }

    return null;
  }

  /// Normaliza un nombre para comparación tolerante
  String _normalizar(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ===========================================================================
  // HEALTH CHECK (opcional, debug-only)
  // ===========================================================================

  Future<bool> isHealthy() async {
    if (!PredictConfig.enabled) return false;
    try {
      final uri = Uri.parse(
          '${PredictConfig.baseUrl}${PredictConfig.healthEndpoint}');
      final response =
          await _client.get(uri).timeout(PredictConfig.timeout);
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