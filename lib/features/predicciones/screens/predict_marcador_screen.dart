// =============================================================================
// PROGANA Fantasy — PredictMarcadorScreen (Plus/Pro)
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
//   ✓ Score selector dorado con +/-
//   ✓ Card "PRO Próximamente" para Goleador
//   ✓ Botón GUARDAR dorado con estados
//
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../../quinielas/models/quiniela.dart';
import '../../quinielas/models/partido.dart';
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
  final _supabase = Supabase.instance.client;

  // === DATOS ===
  int _golesLocal = 0;
  int _golesVisit = 0;
  int _golesLocalOriginal = 0;
  int _golesVisitOriginal = 0;
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
        _golesLocal = prediccion.predLocal ?? 0;
        _golesVisit = prediccion.predVisit ?? 0;
        _golesLocalOriginal = _golesLocal;
        _golesVisitOriginal = _golesVisit;
      }

      // 3. Calcular countdown desde fechaCierrePredicciones
      _calcularCountdown();
      _startCountdown();

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
  // ACTIONS
  // ===========================================================================

  void _incrementLocal() {
    if (_golesLocal < 20) setState(() => _golesLocal++);
  }

  void _decrementLocal() {
    if (_golesLocal > 0) setState(() => _golesLocal--);
  }

  void _incrementVisit() {
    if (_golesVisit < 20) setState(() => _golesVisit++);
  }

  void _decrementVisit() {
    if (_golesVisit > 0) setState(() => _golesVisit--);
  }

  bool get _hasChanges =>
      _golesLocal != _golesLocalOriginal ||
      _golesVisit != _golesVisitOriginal;

  bool get _puedePredecir =>
      _timeRemaining.inSeconds > 0 &&
      widget.partido.estado.permitePredecir &&
      _miTier.puedeMarcador;

  Future<void> _guardarPrediccion() async {
    if (_isSaving || !_puedePredecir) return;

    setState(() => _isSaving = true);

    try {
      final prediccion = await _repo.guardarPrediccion(
        partidoId: widget.partido.id,
        quinielaId: widget.quiniela.id,
        tier: _miTier,
        golesLocal: _golesLocal,
        golesVisit: _golesVisit,
      );

      if (mounted) {
        setState(() {
          _miPrediccion = prediccion;
          _golesLocalOriginal = _golesLocal;
          _golesVisitOriginal = _golesVisit;
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
                  '${widget.partido.equipoLocal?.codigo ?? "?"}  $_golesLocal - $_golesVisit  ${widget.partido.equipoVisit?.codigo ?? "?"}',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
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
                _buildScoreSelector(),
                const SizedBox(height: 24),
                _buildGoleadorCard(),
                const SizedBox(height: 32),
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
            'PREDECIR MARCADOR',
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
  // SCORE SELECTOR
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
  // GOLEADOR CARD — "PRO Próximamente" honesto
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

    // Estado: tier no permite marcador (free)
    if (!_miTier.puedeMarcador) {
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
          'UPGRADE A PLUS PARA PREDECIR',
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.gold,
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