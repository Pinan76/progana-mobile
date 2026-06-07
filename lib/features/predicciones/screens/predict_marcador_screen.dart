// =============================================================================
// PROGANA Fantasy — PredictMarcadorScreen (Free / Plus / Pro)
// =============================================================================
//
// L41 COMPLIANT (3 jun 2026 - Día 8):
//   ✓ Constructor recibe: Quiniela + Partido (objetos completos, no IDs)
//   ✓ Modelo Prediccion + Repository nuevos creados primero
//   ✓ tier_al_predecir desde profile actual (verificado en initState)
//   ✓ pred_resultado calculado AUTO (BD requiere siempre)
//   ✓ UNIQUE constraint respetada (upsert behavior)
//   ✓ Validaciones: countdown > 0, partido programado, tier permite marcador
//   ✓ Goleador como card "PRO Próximamente" honesto (no mock fake)
//   ✓ Compatible Flutter Web (sin dart:io)
//   ✓ .withValues(alpha:) consistente
//   ✓ Timer dispose correcto
//   ✓ mounted checks
//
// DISEÑO MIDNIGHT STADIUM (réplica HTML pantalla 04):
//   ✓ AppBar minimalista con back + título
//   ✓ Countdown LIVE crimson con efecto pulse
//   ✓ Match showcase: banderas grandes + nombres
//   ✓ Score selector dorado con +/- (Plus/Pro)
//   ✓ Card "PRO Próximamente" para Goleador (Plus/Pro)
//   ✓ Botón GUARDAR dorado con estados
//
// FASE 2 4 JUN 2026 (Día 9 PM — Vista condicional por tier):
//   ✓ Free: 3 botones LOCAL / EMPATE / VISITANTE (L/E/V)
//   ✓ Plus/Pro: Selector marcador exacto +/- (UI original)
//   ✓ Goleador card oculto para Free
//   ✓ Dialog éxito adaptado: Free muestra "RESULTADO: LOCAL"
//   ✓ Repository ya soporta ambos flujos (golesLocal/Visit nullable + resultado opcional)
//
// FASE 3 4 JUN 2026 (Día 9 PM — Goleador funcional):
//   ✓ Plus/Pro: Selector goleador con 2 tabs (local | visit), 52 jugadores
//   ✓ Lazy load: jugadores solo se cargan si tier puedeGoleador
//   ✓ Fallback robusto: si BD falla, muestra card "PRÓXIMAMENTE"
//   ✓ Constraint: si predicción es 0-0, goleador se resetea automáticamente
//   ✓ Re-edit: carga goleadorPredichoId de predicción existente
//   ✓ Dialog éxito muestra nombre del goleador si fue seleccionado
//
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../../quinielas/models/quiniela.dart';
import '../../quinielas/models/partido.dart';
import '../../quinielas/models/jugador.dart';
import '../../quinielas/repository/jugador_repository.dart';
import '../models/prediccion.dart';
import '../repository/prediccion_repository.dart';

class PredictMarcadorScreen extends StatefulWidget {
  final Quiniela quiniela;
  final Partido partido;

  const PredictMarcadorScreen({
    super.key,
    required this.quiniela,
    required this.partido,
  });

  @override
  State<PredictMarcadorScreen> createState() => _PredictMarcadorScreenState();
}

class _PredictMarcadorScreenState extends State<PredictMarcadorScreen> {
  final _repo = PrediccionRepository();
  final _jugadorRepo = JugadorRepository();
  final _supabase = Supabase.instance.client;

  // === DATOS Plus/Pro (marcador exacto) ===
  int _golesLocal = 0;
  int _golesVisit = 0;
  int _golesLocalOriginal = 0;
  int _golesVisitOriginal = 0;

  // === DATOS Free (L/E/V) ===
  String? _resultadoSeleccionado;
  String? _resultadoOriginal;

  // === DATOS Goleador (Plus/Pro, opcional) - Fase 3 Día 9 PM ===
  List<Jugador> _jugadoresLocal = [];
  List<Jugador> _jugadoresVisit = [];
  int? _goleadorSeleccionadoId;
  int? _goleadorOriginalId;
  int _tabGoleadorIndex = 0; // 0 = local, 1 = visit
  bool _jugadoresCargados = false;
  bool _jugadoresError = false;

  // === COMÚN ===
  Prediccion? _miPrediccion;
  TierAlPredecir _miTier = TierAlPredecir.free;

  // === ESTADO ===
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // === COUNTDOWN ===
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<void> _initialize() async {
    try {
      // 1. Obtener tier del user actual desde profiles
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No hay sesión activa');
      }

      final profile = await _supabase
          .from('profiles')
          .select('tier')
          .eq('id', user.id)
          .single();

      _miTier = TierAlPredecir.fromString(profile['tier'] as String);

      // 2. Cargar predicción existente (si hay)
      final prediccion = await _repo.obtenerMiPrediccion(
        partidoId: widget.partido.id,
        quinielaId: widget.quiniela.id,
      );

      if (prediccion != null) {
        _miPrediccion = prediccion;
        // Para Plus/Pro: cargar marcador
        _golesLocal = prediccion.predLocal ?? 0;
        _golesVisit = prediccion.predVisit ?? 0;
        _golesLocalOriginal = _golesLocal;
        _golesVisitOriginal = _golesVisit;
        // Para Free: cargar resultado L/E/V
        _resultadoSeleccionado = prediccion.predResultado;
        _resultadoOriginal = prediccion.predResultado;
        // Goleador (Plus/Pro, opcional)
        _goleadorSeleccionadoId = prediccion.goleadorPredichoId;
        _goleadorOriginalId = prediccion.goleadorPredichoId;
      }

      // 3. Calcular countdown desde fechaCierrePredicciones
      _calcularCountdown();
      _startCountdown();

      // 4. Cargar jugadores SOLO si tier puede goleador (Plus/Pro)
      // Lazy fire-and-forget: no bloquea la pantalla
      if (_miTier.puedeGoleador) {
        _cargarJugadoresPartido();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ===========================================================================
  // FASE 3 (Día 9 PM): Cargar jugadores del partido
  // ===========================================================================

  Future<void> _cargarJugadoresPartido() async {
    final local = widget.partido.equipoLocal;
    final visit = widget.partido.equipoVisit;

    // Si los equipos no están definidos aún, no se puede cargar
    if (local == null || visit == null) {
      if (mounted) {
        setState(() => _jugadoresError = true);
      }
      return;
    }

    try {
      final resultado = await _jugadorRepo.obtenerJugadoresDelPartido(
        equipoLocalId: local.id,
        equipoVisitId: visit.id,
      );

      if (mounted) {
        setState(() {
          _jugadoresLocal = resultado.local;
          _jugadoresVisit = resultado.visit;
          _jugadoresCargados = true;
          _jugadoresError = false;
        });
      }
    } catch (_) {
      // Si falla, fallback al card "PRÓXIMAMENTE"
      if (mounted) {
        setState(() {
          _jugadoresCargados = false;
          _jugadoresError = true;
        });
      }
    }
  }

  void _calcularCountdown() {
    final ahora = DateTime.now();
    final cierre = widget.partido.fechaCierrePredicciones;

    if (cierre.isAfter(ahora)) {
      _timeRemaining = cierre.difference(ahora);
    } else {
      _timeRemaining = Duration.zero;
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _calcularCountdown();
      });
    });
  }

  String _formatCountdown(Duration d) {
    if (d.inSeconds <= 0) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ===========================================================================
  // ACTIONS — Plus/Pro (marcador)
  // ===========================================================================

  void _incrementLocal() {
    if (_golesLocal < 20) {
      setState(() {
        _golesLocal++;
        _resetGoleadorSiEmpateCero();
      });
    }
  }

  void _decrementLocal() {
    if (_golesLocal > 0) {
      setState(() {
        _golesLocal--;
        _resetGoleadorSiEmpateCero();
      });
    }
  }

  void _incrementVisit() {
    if (_golesVisit < 20) {
      setState(() {
        _golesVisit++;
        _resetGoleadorSiEmpateCero();
      });
    }
  }

  void _decrementVisit() {
    if (_golesVisit > 0) {
      setState(() {
        _golesVisit--;
        _resetGoleadorSiEmpateCero();
      });
    }
  }

  /// Si la predicción quedó en 0-0, resetea goleador automáticamente
  /// (constraint BD: check_goleador_sin_empate_cero)
  void _resetGoleadorSiEmpateCero() {
    if (_golesLocal == 0 && _golesVisit == 0) {
      _goleadorSeleccionadoId = null;
    }
  }

  // ===========================================================================
  // ACTIONS — Free (L/E/V)
  // ===========================================================================

  void _seleccionarResultado(String resultado) {
    setState(() => _resultadoSeleccionado = resultado);
  }

  // ===========================================================================
  // ACTIONS — Goleador (Plus/Pro, opcional)
  // ===========================================================================

  void _seleccionarGoleador(int jugadorId) {
    setState(() {
      // Toggle: si ya estaba seleccionado, deseleccionar
      _goleadorSeleccionadoId =
          _goleadorSeleccionadoId == jugadorId ? null : jugadorId;
    });
  }

  void _cambiarTabGoleador(int index) {
    setState(() => _tabGoleadorIndex = index);
  }

  /// Obtiene el nombre del jugador goleador seleccionado (para dialog éxito)
  String? _nombreGoleadorSeleccionado() {
    if (_goleadorSeleccionadoId == null) return null;
    final todos = [..._jugadoresLocal, ..._jugadoresVisit];
    try {
      final jugador =
          todos.firstWhere((j) => j.id == _goleadorSeleccionadoId);
      return jugador.nombre;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // ESTADO BUTTON / VALIDACIONES
  // ===========================================================================

  bool get _hasChanges {
    if (_miTier == TierAlPredecir.free) {
      return _resultadoSeleccionado != _resultadoOriginal;
    }
    // Plus/Pro: cambio en marcador O en goleador
    return _golesLocal != _golesLocalOriginal ||
        _golesVisit != _golesVisitOriginal ||
        _goleadorSeleccionadoId != _goleadorOriginalId;
  }

  bool get _puedePredecir =>
      _timeRemaining.inSeconds > 0 &&
      widget.partido.estado.permitePredecir;

  bool get _tieneValorParaGuardar {
    if (_miTier == TierAlPredecir.free) {
      return _resultadoSeleccionado != null;
    }
    // Plus/Pro siempre tienen valor (default 0-0)
    return true;
  }

  /// Si debe mostrar selector funcional de goleador (vs card placeholder)
  bool get _mostrarSelectorGoleadorFuncional {
    return _miTier.puedeGoleador &&
        _jugadoresCargados &&
        !_jugadoresError &&
        (_jugadoresLocal.isNotEmpty || _jugadoresVisit.isNotEmpty);
  }

  /// Si el goleador puede ser seleccionado (no es 0-0)
  bool get _goleadorEsSeleccionable {
    if (!_puedePredecir) return false;
    // Si la predicción es 0-0, goleador deshabilitado
    return !(_golesLocal == 0 && _golesVisit == 0);
  }

  // ===========================================================================
  // GUARDAR PREDICCIÓN
  // ===========================================================================

  Future<void> _guardarPrediccion() async {
    if (_isSaving || !_puedePredecir || !_tieneValorParaGuardar) return;

    setState(() => _isSaving = true);

    try {
      late Prediccion prediccion;

      if (_miTier == TierAlPredecir.free) {
        // Free: solo resultado L/E/V (sin goleador)
        prediccion = await _repo.guardarPrediccion(
          partidoId: widget.partido.id,
          quinielaId: widget.quiniela.id,
          tier: _miTier,
          resultado: _resultadoSeleccionado,
        );
      } else {
        // Plus/Pro: marcador exacto + goleador opcional
        prediccion = await _repo.guardarPrediccion(
          partidoId: widget.partido.id,
          quinielaId: widget.quiniela.id,
          tier: _miTier,
          golesLocal: _golesLocal,
          golesVisit: _golesVisit,
          goleadorPredichoId: _goleadorSeleccionadoId,
        );
      }

      if (mounted) {
        setState(() {
          _miPrediccion = prediccion;
          // Reset originales según tier
          if (_miTier == TierAlPredecir.free) {
            _resultadoOriginal = _resultadoSeleccionado;
          } else {
            _golesLocalOriginal = _golesLocal;
            _golesVisitOriginal = _golesVisit;
            _goleadorOriginalId = _goleadorSeleccionadoId;
          }
          _isSaving = false;
        });
        _mostrarDialogExito();
      }
    } on TierInvalidoException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar(e.message, ProganaColors.crimson);
      }
    } on PrediccionException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar(e.message, ProganaColors.crimson);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error: $e', ProganaColors.crimson);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: ProganaColors.cream,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _mostrarDialogExito() {
    // Texto del marcador/resultado según tier
    final String displayValor;
    if (_miTier == TierAlPredecir.free) {
      final etiqueta = ResultadoPartido.etiqueta(_resultadoSeleccionado ?? 'L');
      displayValor = 'RESULTADO: ${etiqueta.toUpperCase()}';
    } else {
      final localCode = widget.partido.equipoLocal?.codigo ?? '?';
      final visitCode = widget.partido.equipoVisit?.codigo ?? '?';
      displayValor = '$localCode  $_golesLocal - $_golesVisit  $visitCode';
    }

    // Goleador (solo si Plus/Pro lo seleccionó)
    final goleadorNombre = _nombreGoleadorSeleccionado();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: ProganaColors.midnight2,
            border: Border.all(
              color: ProganaColors.gold.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ProganaColors.gold.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [ProganaColors.gold, ProganaColors.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ProganaColors.gold.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: ProganaColors.midnight,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡PREDICCIÓN GUARDADA!',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ProganaColors.midnight3,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValor,
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Goleador (si fue seleccionado - Fase 3)
              if (goleadorNombre != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ProganaColors.emerald.withValues(alpha: 0.15),
                    border: Border.all(
                      color: ProganaColors.emerald.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚽', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        'Goleador: $goleadorNombre',
                        style: GoogleFonts.outfit(
                          color: ProganaColors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Puedes modificarla hasta el cierre de predicciones',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: ProganaColors.creamDim,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Cierra dialog
                    Navigator.of(context).pop(true); // Cierra pantalla con resultado
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProganaColors.gold,
                    foregroundColor: ProganaColors.midnight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CONTINUAR',
                    style: GoogleFonts.archivoBlack(
                      color: ProganaColors.midnight,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProganaColors.midnight,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildSuccessState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: ProganaColors.gold,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              'ERROR DE CONEXIÓN',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.crimson,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ProganaColors.creamDim,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProganaColors.gold,
                foregroundColor: ProganaColors.midnight,
              ),
              child: Text(
                'VOLVER',
                style: GoogleFonts.archivoBlack(
                  fontSize: 11,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final esFree = _miTier == TierAlPredecir.free;

    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCountdown(),
                const SizedBox(height: 24),
                _buildMatchShowcase(),
                const SizedBox(height: 32),
                // Selector condicional según tier
                if (esFree)
                  _buildLEVSelector()
                else
                  _buildScoreSelector(),
                const SizedBox(height: 24),
                // Goleador (Fase 3): selector funcional o card placeholder
                if (!esFree) ...[
                  if (_mostrarSelectorGoleadorFuncional)
                    _buildGoleadorSelector()
                  else
                    _buildGoleadorCard(),
                  const SizedBox(height: 32),
                ],
                // Para Free, espaciado equivalente
                if (esFree) const SizedBox(height: 8),
                _buildSubmitButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================

  Widget _buildAppBar() {
    final titulo = _miTier == TierAlPredecir.free
        ? 'PREDECIR RESULTADO'
        : 'PREDECIR MARCADOR';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ProganaColors.gold.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProganaColors.midnight2,
                border: Border.all(
                  color: ProganaColors.gold.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: ProganaColors.cream,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            titulo,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COUNTDOWN LIVE
  // ===========================================================================

  Widget _buildCountdown() {
    final isAbierto = _timeRemaining.inSeconds > 0;
    final color = isAbierto ? ProganaColors.crimson : ProganaColors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: isAbierto
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAbierto ? 'CIERRA EN' : 'PREDICCIONES CERRADAS',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          if (isAbierto) ...[
            const SizedBox(width: 8),
            Text(
              _formatCountdown(_timeRemaining),
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // MATCH SHOWCASE
  // ===========================================================================

  Widget _buildMatchShowcase() {
    final local = widget.partido.equipoLocal;
    final visit = widget.partido.equipoVisit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildTeamShowcase(
                emoji: local?.emojiBandera ?? '🏳️',
                codigo: local?.codigo ?? 'TBD',
                nombre: local?.nombre ?? 'Por definir',
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'VS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.archivoBlack(
                    color: ProganaColors.gold,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _buildTeamShowcase(
                emoji: visit?.emojiBandera ?? '🏳️',
                codigo: visit?.codigo ?? 'TBD',
                nombre: visit?.nombre ?? 'Por definir',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.partido.horaFormateada} · ${widget.partido.ciudad ?? "Por definir"}',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamShowcase({
    required String emoji,
    required String codigo,
    required String nombre,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 56,
            decoration: BoxDecoration(
              color: ProganaColors.midnight3,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 10),
          Text(
            codigo,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nombre.toUpperCase(),
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // L/E/V SELECTOR — Free Tier (FASE 2 Día 9)
  // ===========================================================================

  Widget _buildLEVSelector() {
    final local = widget.partido.equipoLocal;
    final visit = widget.partido.equipoVisit;
    final localCode = local?.codigo ?? '?';
    final visitCode = visit?.codigo ?? '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'TU PREDICCIÓN',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿QUIÉN GANARÁ?',
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // 3 botones LOCAL / EMPATE / VISITANTE
          Row(
            children: [
              Expanded(
                child: _buildLEVButton(
                  resultado: ResultadoPartido.local,
                  label: 'LOCAL',
                  subtext: localCode,
                  emoji: local?.emojiBandera ?? '🏳️',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLEVButton(
                  resultado: ResultadoPartido.empate,
                  label: 'EMPATE',
                  subtext: 'X',
                  emoji: '🤝',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLEVButton(
                  resultado: ResultadoPartido.visitante,
                  label: 'VISIT.',
                  subtext: visitCode,
                  emoji: visit?.emojiBandera ?? '🏳️',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hint upgrade Plus
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ProganaColors.gold.withValues(alpha: 0.05),
              border: Border.all(
                color: ProganaColors.gold.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: ProganaColors.gold,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Con Plus: predice el marcador exacto (3 pts vs 1 pt)',
                    style: GoogleFonts.outfit(
                      color: ProganaColors.cream,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLEVButton({
    required String resultado,
    required String label,
    required String subtext,
    required String emoji,
  }) {
    final isSelected = _resultadoSeleccionado == resultado;
    final isEnabled = _puedePredecir;

    return GestureDetector(
      onTap: isEnabled ? () => _seleccionarResultado(resultado) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [ProganaColors.gold, ProganaColors.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : ProganaColors.midnight2,
          border: Border.all(
            color: isSelected
                ? ProganaColors.goldBright
                : ProganaColors.gold.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ProganaColors.gold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.archivoBlack(
                color: isSelected
                    ? ProganaColors.midnight
                    : ProganaColors.cream,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: GoogleFonts.jetBrainsMono(
                color: isSelected
                    ? ProganaColors.midnight.withValues(alpha: 0.7)
                    : ProganaColors.creamDim,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCORE SELECTOR — Plus/Pro Tier
  // ===========================================================================

  Widget _buildScoreSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'TU PREDICCIÓN',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreColumn(
                goles: _golesLocal,
                onIncrement: _incrementLocal,
                onDecrement: _decrementLocal,
              ),
              const SizedBox(width: 24),
              Text(
                '–',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.creamDim,
                  fontSize: 40,
                ),
              ),
              const SizedBox(width: 24),
              _buildScoreColumn(
                goles: _golesVisit,
                onIncrement: _incrementVisit,
                onDecrement: _decrementVisit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resultado: ${ResultadoPartido.etiqueta(ResultadoPartido.calcular(_golesLocal, _golesVisit))}',
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn({
    required int goles,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        _buildScoreButton(
          icon: Icons.add_rounded,
          onTap: _puedePredecir ? onIncrement : null,
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ProganaColors.gold.withValues(alpha: 0.15),
                ProganaColors.gold.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: ProganaColors.gold.withValues(alpha: 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            goles.toString(),
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.gold,
              fontSize: 40,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildScoreButton(
          icon: Icons.remove_rounded,
          onTap: _puedePredecir ? onDecrement : null,
        ),
      ],
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled
              ? ProganaColors.midnight2
              : ProganaColors.midnight2.withValues(alpha: 0.5),
          border: Border.all(
            color: isEnabled
                ? ProganaColors.gold.withValues(alpha: 0.4)
                : ProganaColors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isEnabled ? ProganaColors.gold : ProganaColors.grey,
          size: 20,
        ),
      ),
    );
  }

  // ===========================================================================
  // GOLEADOR SELECTOR — Plus/Pro Funcional (FASE 3 Día 9 PM)
  // ===========================================================================

  Widget _buildGoleadorSelector() {
    final esEmpateCero = _golesLocal == 0 && _golesVisit == 0;
    final goleadorActual = _nombreGoleadorSeleccionado();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚽', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'GOLEADOR (+1 PT)',
                    style: GoogleFonts.jetBrainsMono(
                      color: ProganaColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              if (goleadorActual != null)
                GestureDetector(
                  onTap: _goleadorEsSeleccionable
                      ? () => setState(() => _goleadorSeleccionadoId = null)
                      : null,
                  child: Text(
                    'LIMPIAR',
                    style: GoogleFonts.jetBrainsMono(
                      color: ProganaColors.creamDim,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            esEmpateCero
                ? 'No disponible en empate sin goles'
                : 'Opcional - elige quién anotará primero',
            style: GoogleFonts.outfit(
              color: esEmpateCero
                  ? ProganaColors.crimson.withValues(alpha: 0.7)
                  : ProganaColors.creamDim,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Si es empate 0-0, mostrar mensaje deshabilitado
          if (esEmpateCero)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProganaColors.midnight2.withValues(alpha: 0.4),
                border: Border.all(
                  color: ProganaColors.crimson.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: ProganaColors.crimson,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cambia el marcador a algo distinto de 0-0 para elegir goleador.',
                      style: GoogleFonts.outfit(
                        color: ProganaColors.creamDim,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Tabs Local / Visit
            _buildTabSelector(),
            const SizedBox(height: 8),
            // Lista de jugadores tab activa
            _buildListaJugadores(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final local = widget.partido.equipoLocal;
    final visit = widget.partido.equipoVisit;

    return Container(
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              emoji: local?.emojiBandera ?? '🏳️',
              codigo: local?.codigo ?? '?',
              count: _jugadoresLocal.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              emoji: visit?.emojiBandera ?? '🏳️',
              codigo: visit?.codigo ?? '?',
              count: _jugadoresVisit.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String emoji,
    required String codigo,
    required int count,
  }) {
    final isActive = _tabGoleadorIndex == index;
    return GestureDetector(
      onTap: () => _cambiarTabGoleador(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    ProganaColors.gold.withValues(alpha: 0.2),
                    ProganaColors.gold.withValues(alpha: 0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? ProganaColors.gold
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              codigo,
              style: GoogleFonts.archivoBlack(
                color: isActive ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$count jugadores',
              style: GoogleFonts.jetBrainsMono(
                color: isActive
                    ? ProganaColors.gold.withValues(alpha: 0.7)
                    : ProganaColors.creamDim,
                fontSize: 8,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaJugadores() {
    final lista =
        _tabGoleadorIndex == 0 ? _jugadoresLocal : _jugadoresVisit;

    // Banner clarificador L41 - Fase 3 Día 9 PM
    final equipoActivo = _tabGoleadorIndex == 0
        ? widget.partido.equipoLocal
        : widget.partido.equipoVisit;
    final emojiBanner = equipoActivo?.emojiBandera ?? '🏳️';
    final nombreBanner =
        equipoActivo?.nombre.toUpperCase() ?? 'EQUIPO';

    if (lista.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          'Sin jugadores registrados',
          style: GoogleFonts.outfit(
            color: ProganaColors.creamDim,
            fontSize: 11,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner clarificador del equipo activo
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ProganaColors.gold.withValues(alpha: 0.15),
                ProganaColors.gold.withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              left: BorderSide(
                color: ProganaColors.gold,
                width: 3,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Text(emojiBanner, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'JUGADORES DE $nombreBanner',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                '${lista.length}',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.gold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Lista scrollable con altura limitada (no expande infinito)
        Container(
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: ProganaColors.midnight2.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: lista.length,
            itemBuilder: (context, index) => _buildJugadorTile(lista[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildJugadorTile(Jugador jugador) {
    final isSelected = _goleadorSeleccionadoId == jugador.id;
    final isEnabled = _goleadorEsSeleccionable;

    return GestureDetector(
      onTap: isEnabled ? () => _seleccionarGoleador(jugador.id) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    ProganaColors.gold.withValues(alpha: 0.25),
                    ProganaColors.gold.withValues(alpha: 0.1),
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected
                ? ProganaColors.gold
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Emoji posición
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ProganaColors.midnight3,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                jugador.emojiPosicion,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre + posición
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          jugador.nombre,
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? ProganaColors.gold
                                : ProganaColors.cream,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (jugador.esMaximaEstrella) ...[
                        const SizedBox(width: 4),
                        const Text('⭐', style: TextStyle(fontSize: 10)),
                      ] else if (jugador.esEstrella) ...[
                        const SizedBox(width: 4),
                        const Text('✨', style: TextStyle(fontSize: 9)),
                      ],
                    ],
                  ),
                  Text(
                    '${jugador.posicionDisplay} · ${jugador.golesCarrera}g',
                    style: GoogleFonts.jetBrainsMono(
                      color: ProganaColors.creamDim,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Check si está seleccionado
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: ProganaColors.gold,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GOLEADOR CARD — Fallback "PRO Próximamente" (si BD falla / Free)
  // ===========================================================================

  Widget _buildGoleadorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProganaColors.midnight2.withValues(alpha: 0.6),
          border: Border.all(
            color: ProganaColors.gold.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ProganaColors.gold.withValues(alpha: 0.15),
                    border: Border.all(
                      color: ProganaColors.gold.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: ProganaColors.gold,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PRO · PRÓXIMAMENTE',
                        style: GoogleFonts.jetBrainsMono(
                          color: ProganaColors.gold,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ProganaColors.midnight3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⚽', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goleador (+1 pt)',
                        style: GoogleFonts.outfit(
                          color: ProganaColors.cream,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Disponible en el Mundial (11 jun)',
                        style: GoogleFonts.outfit(
                          color: ProganaColors.creamDim,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SUBMIT BUTTON
  // ===========================================================================

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildButtonState(),
    );
  }

  Widget _buildButtonState() {
    // Estado: predicciones cerradas
    if (_timeRemaining.inSeconds <= 0) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: ProganaColors.midnight2,
          border: Border.all(color: ProganaColors.crimson.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          'PREDICCIONES CERRADAS',
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.crimson,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    // Estado: saving
    if (_isSaving) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: ProganaColors.gold.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: ProganaColors.midnight,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Estado: Free pero no ha seleccionado nada todavía
    if (_miTier == TierAlPredecir.free && _resultadoSeleccionado == null) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: ProganaColors.midnight2,
          border: Border.all(color: ProganaColors.gold.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          'SELECCIONA TU PREDICCIÓN',
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.gold,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    // Estado: ya guardada y sin cambios
    if (_miPrediccion != null && !_hasChanges) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ProganaColors.emerald, ProganaColors.emeraldDeep],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ProganaColors.emerald.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: ProganaColors.cream,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'PREDICCIÓN GUARDADA',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.cream,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Estado: listo para guardar
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _guardarPrediccion,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProganaColors.gold,
          foregroundColor: ProganaColors.midnight,
          elevation: 12,
          shadowColor: ProganaColors.gold.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flash_on_rounded,
              color: ProganaColors.midnight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _miPrediccion == null ? 'GUARDAR PREDICCIÓN' : 'ACTUALIZAR',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.midnight,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}