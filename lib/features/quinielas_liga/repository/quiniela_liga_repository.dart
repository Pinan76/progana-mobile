import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiniela_liga.dart';
import '../models/partido_liga.dart';
import '../models/participacion_liga.dart';
import '../models/mi_quiniela_liga.dart';

/// Repositorio del Motor 2 (quinielas de clubes) vía Supabase.
///
/// L41: queries verificadas contra schema real (jun 2026).
/// Aislado del Motor 1 (Mundial): usa tablas/vistas *_liga y RPCs propios
/// (crear_quiniela_liga, get_partidos_quiniela, activar_quiniela_liga,
/// actualizar_estados_quinielas_liga).
/// Estado de mis predicciones en una quiniela (para bloquear la UI).
class EstadoPrediccion {
  final bool confirmada;
  final DateTime? deadline;
  final int totalPartidos;
  final int totalPicks;

  EstadoPrediccion({
    required this.confirmada,
    this.deadline,
    required this.totalPartidos,
    required this.totalPicks,
  });

  factory EstadoPrediccion.fromJson(Map<String, dynamic> j) => EstadoPrediccion(
        confirmada: (j['confirmada'] as bool?) ?? false,
        deadline: j['deadline'] != null
            ? DateTime.parse(j['deadline'] as String)
            : null,
        totalPartidos: (j['total_partidos'] as int?) ?? 0,
        totalPicks: (j['total_picks'] as int?) ?? 0,
      );

  bool cerrada(DateTime now) => deadline == null || !now.isBefore(deadline!);
}

/// Estado del panel de transparencia.
class PanelEstado {
  final bool revelada;
  final DateTime? deadline;
  final int activos;
  final int? capacidad;
  final int confirmados;
  final int totalPartidos;

  PanelEstado({
    required this.revelada,
    this.deadline,
    required this.activos,
    this.capacidad,
    required this.confirmados,
    required this.totalPartidos,
  });

  factory PanelEstado.fromJson(Map<String, dynamic> j) => PanelEstado(
        revelada: (j['revelada'] as bool?) ?? false,
        deadline: j['deadline'] != null
            ? DateTime.parse(j['deadline'] as String)
            : null,
        activos: (j['activos'] as num?)?.toInt() ?? 0,
        capacidad: (j['capacidad'] as num?)?.toInt(),
        confirmados: (j['confirmados'] as num?)?.toInt() ?? 0,
        totalPartidos: (j['total_partidos'] as num?)?.toInt() ?? 0,
      );
}

/// Un pick dentro del panel (participante × partido).
class PanelPick {
  final int participacionId;
  final String nickname;
  final int partidoId;
  final String pred;
  final String? resultado;
  final bool? acierto;
  final bool esMio;

  PanelPick({
    required this.participacionId,
    required this.nickname,
    required this.partidoId,
    required this.pred,
    this.resultado,
    this.acierto,
    required this.esMio,
  });

  factory PanelPick.fromJson(Map<String, dynamic> j) => PanelPick(
        participacionId: (j['participacion_id'] as num).toInt(),
        nickname: (j['nickname'] as String?) ?? 'Jugador',
        partidoId: (j['partido_liga_id'] as num).toInt(),
        pred: (j['pred_resultado'] as String).trim(),
        resultado: (j['partido_resultado'] as String?)?.trim(),
        acierto: j['acierto'] as bool?,
        esMio: (j['es_mio'] as bool?) ?? false,
      );
}

/// Entrada del ranking (reusa get_ranking_liga).
class RankingEntry {
  final int posicion;
  final int participacionId;
  final String nickname;
  final int aciertos;
  final int partidosJugados;
  final int totalPredicciones;

  RankingEntry({
    required this.posicion,
    required this.participacionId,
    required this.nickname,
    required this.aciertos,
    required this.partidosJugados,
    required this.totalPredicciones,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j) => RankingEntry(
        posicion: (j['posicion'] as num).toInt(),
        participacionId: (j['participacion_id'] as num).toInt(),
        nickname: (j['nickname'] as String?) ?? 'Jugador',
        aciertos: (j['aciertos'] as num?)?.toInt() ?? 0,
        partidosJugados: (j['partidos_jugados'] as num?)?.toInt() ?? 0,
        totalPredicciones: (j['total_predicciones'] as num?)?.toInt() ?? 0,
      );
}

class QuinielaLigaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Precio por participante en MXN (sin brackets).
  static const double precioPorParticipante = 3.5;
  static double costoEstimado(int capacidad) =>
      capacidad * precioPorParticipante;

  /// Rango de partidos permitido por quiniela.
  static const int minPartidos = 8;
  static const int maxPartidos = 14;

  // ===========================================================================
  // STATE MACHINE REACTIVO
  // ===========================================================================
  Future<void> _refrescarEstados() async {
    try {
      await _supabase.rpc('actualizar_estados_quinielas_liga');
    } catch (_) {
      // L41 fail-safe: silencioso
    }
  }

  // ===========================================================================
  // CATÁLOGO
  // ===========================================================================

  Future<List<Competicion>> getCompeticiones() async {
    try {
      final rows = await _supabase
          .from('competiciones')
          .select('id, nombre, nombre_corto')
          .order('id', ascending: true);
      return (rows as List)
          .map((j) => Competicion.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar ligas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar ligas: $e');
    }
  }

  Future<List<PartidoLiga>> getPartidosDisponibles(int competicionId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      final rows = await _supabase
          .from('v_partidos_liga_detalle')
          .select()
          .eq('competicion_id', competicionId)
          .eq('estado', 'programado')
          .gt('fecha_hora', nowIso)
          .order('fecha_hora', ascending: true);
      return (rows as List)
          .map((j) => PartidoLiga.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar partidos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar partidos: $e');
    }
  }

  /// Partidos elegidos de una quiniela (para la pantalla de detalle).
  Future<List<PartidoLiga>> getPartidosDeQuiniela(int quinielaId) async {
    try {
      final rows = await _supabase.rpc(
        'get_partidos_quiniela',
        params: {'p_quiniela_id': quinielaId},
      );
      return (rows as List)
          .map((j) => PartidoLiga.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar partidos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar partidos: $e');
    }
  }

  // ===========================================================================
  // COMANDOS
  // ===========================================================================

  Future<QuinielaLiga> crearQuinielaConPartidos({
    required String nombre,
    String? descripcion,
    required int capacidad,
    required List<int> partidoIds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para crear una quiniela.');
    }
    try {
      final response = await _supabase.rpc('crear_quiniela_liga', params: {
        'p_nombre': nombre.trim(),
        'p_descripcion': descripcion?.trim(),
        'p_capacidad': capacidad,
        'p_partido_ids': partidoIds,
      });
      final map = response is List
          ? (response.first as Map<String, dynamic>)
          : (response as Map<String, dynamic>);
      return QuinielaLiga.fromJson(map);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al crear quiniela: $e');
    }
  }

  /// Activa una quiniela: marca el pago y la mueve de borrador → inscripción.
  ///
  /// [gratis] = true  → modo prueba (estado_pago='gratis').
  /// [gratis] = false → tras un pago real (estado_pago='pagado', OpenPay futuro).
  ///
  /// Solo el promotor puede activar (lo valida el RPC SECURITY DEFINER).
  Future<QuinielaLiga> activarQuiniela(int quinielaId,
      {bool gratis = true}) async {
    try {
      final response = await _supabase.rpc('activar_quiniela_liga', params: {
        'p_quiniela_id': quinielaId,
        'p_gratis': gratis,
      });
      final map = response is List
          ? (response.first as Map<String, dynamic>)
          : (response as Map<String, dynamic>);
      return QuinielaLiga.fromJson(map);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al activar quiniela: $e');
    }
  }

  /// El participante se une a una quiniela con el código de invitación.
  /// Queda en estado 'confirmado_plus'. Devuelve el id de la participación.
  ///
  /// [nombre] opcional → se guarda en datos_confirmacion para que el
  /// promotor identifique al participante (profiles puede no tener nombre).
  Future<int> unirsePorCodigo(String codigo, {String? nombre}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para unirte.');
    }
    final cod = codigo.trim();
    if (cod.isEmpty) {
      throw Exception('Escribe el código de invitación.');
    }
    try {
      final Map<String, dynamic>? datos =
          (nombre != null && nombre.trim().isNotEmpty)
              ? {'nombre': nombre.trim()}
              : null;
      final response = await _supabase.rpc('unirse_por_codigo', params: {
        'p_codigo': cod,
        'p_datos': datos,
      });
      return response as int;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al unirse: $e');
    }
  }

  /// El promotor confirma a un participante → pasa a 'activo' (puede predecir).
  /// El RPC valida que sea el promotor y que no exceda la capacidad.
  Future<void> confirmarParticipacion(int participacionId) async {
    try {
      await _supabase.rpc('confirmar_participacion_pro',
          params: {'p_participacion_id': participacionId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al confirmar: $e');
    }
  }

  /// El promotor rechaza a un participante → pasa a 'rechazado'.
  Future<void> rechazarParticipacion(int participacionId) async {
    try {
      await _supabase.rpc('rechazar_participacion',
          params: {'p_participacion_id': participacionId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al rechazar: $e');
    }
  }

  // ===========================================================================
  // QUERIES
  // ===========================================================================

  /// Participantes de una quiniela (solo el promotor puede verlos).
  Future<List<ParticipacionLiga>> getParticipaciones(int quinielaId) async {
    try {
      final rows = await _supabase.rpc(
        'get_participaciones_quiniela',
        params: {'p_quiniela_id': quinielaId},
      );
      return (rows as List)
          .map((j) => ParticipacionLiga.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar participantes: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar participantes: $e');
    }
  }

  /// Mis predicciones L/E/V de una participación → {partidoId: 'L'|'E'|'V'}.
  Future<Map<int, String>> getMisPredicciones(int participacionId) async {
    try {
      final rows = await _supabase.rpc('get_mis_predicciones_liga',
          params: {'p_participacion_id': participacionId});
      final map = <int, String>{};
      for (final r in (rows as List)) {
        final m = r as Map<String, dynamic>;
        map[m['partido_liga_id'] as int] =
            (m['pred_resultado'] as String).trim();
      }
      return map;
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar predicciones: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar predicciones: $e');
    }
  }

  /// Guarda en lote mis predicciones (por participación). Devuelve cuántas.
  Future<int> guardarPredicciones(
      int participacionId, Map<int, String> picks) async {
    try {
      final lista = picks.entries
          .map((e) => {'partido_liga_id': e.key, 'resultado': e.value})
          .toList();
      final res = await _supabase.rpc('guardar_predicciones_liga', params: {
        'p_participacion_id': participacionId,
        'p_predicciones': lista,
      });
      return (res as num).toInt();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al guardar predicciones: $e');
    }
  }

  /// Estado de mis predicciones (confirmada + deadline + progreso).
  Future<EstadoPrediccion> getMiEstadoPrediccion(int participacionId) async {
    try {
      final rows = await _supabase.rpc('get_mi_estado_prediccion',
          params: {'p_participacion_id': participacionId});
      final lista = rows as List;
      if (lista.isEmpty) {
        return EstadoPrediccion(
            confirmada: false, totalPartidos: 0, totalPicks: 0);
      }
      return EstadoPrediccion.fromJson(lista.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar estado: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar estado: $e');
    }
  }

  /// Confirma (bloquea) mis predicciones de una participación. Irreversible.
  Future<void> confirmarMisPredicciones(int participacionId) async {
    try {
      await _supabase.rpc('confirmar_mis_predicciones_liga',
          params: {'p_participacion_id': participacionId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al confirmar: $e');
    }
  }

  /// Crea OTRA participación en una quiniela donde ya participo (nickname++).
  Future<int> nuevaParticipacion(int quinielaId) async {
    try {
      final res = await _supabase.rpc('nueva_participacion_liga',
          params: {'p_quiniela_id': quinielaId});
      return (res as num).toInt();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al crear participación: $e');
    }
  }

  /// Estado del panel de transparencia.
  Future<PanelEstado> getPanelEstado(int quinielaId) async {
    try {
      final rows = await _supabase
          .rpc('get_panel_estado_liga', params: {'p_quiniela_id': quinielaId});
      final lista = rows as List;
      return PanelEstado.fromJson(lista.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar panel: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar panel: $e');
    }
  }

  /// Matriz de picks (ocultos hasta el revelado; solo confirmados).
  Future<List<PanelPick>> getPanelPicks(int quinielaId) async {
    try {
      final rows = await _supabase
          .rpc('get_panel_picks_liga', params: {'p_quiniela_id': quinielaId});
      return (rows as List)
          .map((j) => PanelPick.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar picks: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar picks: $e');
    }
  }

  /// Ranking por aciertos (reusa get_ranking_liga).
  Future<List<RankingEntry>> getRanking(int quinielaId) async {
    try {
      final rows = await _supabase
          .rpc('get_ranking_liga', params: {'p_quiniela_id': quinielaId});
      return (rows as List)
          .map((j) => RankingEntry.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar ranking: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar ranking: $e');
    }
  }

  /// Quinielas de clubes donde el usuario actual PARTICIPA (+ su estado).
  Future<List<MiQuinielaLiga>> misParticipaciones() async {
    _refrescarEstados(); // fire-and-forget
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final rows = await _supabase.rpc('mis_participaciones_liga');
      return (rows as List)
          .map((j) => MiQuinielaLiga.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar participaciones: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar participaciones: $e');
    }
  }

  Future<List<QuinielaLiga>> misQuinielas() async {
    _refrescarEstados(); // fire-and-forget
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _supabase
          .from('quinielas_liga')
          .select()
          .eq('promotor_id', user.id)
          .order('id', ascending: false);
      return (response as List)
          .map((j) => QuinielaLiga.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error BD al cargar quinielas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar quinielas: $e');
    }
  }
}
