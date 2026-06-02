// =============================================================================
// PROGANA Fantasy — Detalle Quiniela Screen (Midnight Stadium)
// =============================================================================
//
// L41 COMPLIANT (2 jun 2026 - Día 7):
//   ✓ Constructor preservado: DetalleQuinielaScreen(quiniela: q)
//   ✓ InscripcionRepository preservado bit-perfect del Día 4
//   ✓ PartidoRepository.obtenerPartidosDeQuiniela() preservado
//   ✓ Botón inscripción 4 estados (verificando/inscrito/procesando/no_inscrito)
//   ✓ Dialog éxito preservado (rediseñado Midnight)
//   ✓ Manejo de InscripcionDuplicadaException preservado
//   ✓ Compatible Flutter Web (sin dart:io)
//   ✓ .withValues(alpha:) consistente
//   ✓ Usa modelos REALES: Quiniela, Partido, Equipo, Inscripcion
//
// DISEÑO MIDNIGHT STADIUM (réplica 99% diseño HTML pantalla 03):
//   ✓ Header verde→midnight gradient + pattern diagonal 45°
//   ✓ Número gigante translúcido decorativo
//   ✓ Sponsor "PATROCINADOR / CERVECERA MX" (demo sponsor)
//   ✓ 3 stat pills (Predichos / Puntos / Posición)
//   ✓ Botón inscripción dorado con 4 estados visuales
//   ✓ Lista partidos compacta: día | equipos | predicción
//   ✓ Dialog éxito midnight2 + check dorado
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/quiniela.dart';
import '../models/partido.dart';
import '../repository/partido_repository.dart';
import '../../inscripciones/models/inscripcion.dart';
import '../../inscripciones/repository/inscripcion_repository.dart';

class DetalleQuinielaScreen extends StatefulWidget {
  final Quiniela quiniela;

  const DetalleQuinielaScreen({super.key, required this.quiniela});

  @override
  State<DetalleQuinielaScreen> createState() => _DetalleQuinielaScreenState();
}

class _DetalleQuinielaScreenState extends State<DetalleQuinielaScreen> {
  final _partidoRepo = PartidoRepository();
  final _inscripcionRepo = InscripcionRepository();
  late Future<List<Partido>> _futurePartidos;

  // Estado de inscripción (preservado Día 4)
  Inscripcion? _miInscripcion;
  bool _verificandoInscripcion = true;
  bool _procesandoInscripcion = false;

  @override
  void initState() {
    super.initState();
    _cargarPartidos();
    _verificarMiInscripcion();
  }

  // ===========================================================================
  // DATA LOADING (preservado bit-perfect del Día 4)
  // ===========================================================================

  void _cargarPartidos() {
    setState(() {
      _futurePartidos =
          _partidoRepo.obtenerPartidosDeQuiniela(widget.quiniela.id);
    });
  }

  Future<void> _verificarMiInscripcion() async {
    try {
      final insc =
          await _inscripcionRepo.verificarInscripcion(widget.quiniela.id);
      if (mounted) {
        setState(() {
          _miInscripcion = insc;
          _verificandoInscripcion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verificandoInscripcion = false);
      }
    }
  }

  Future<void> _inscribirme() async {
    if (_procesandoInscripcion) return;

    setState(() => _procesandoInscripcion = true);

    try {
      final insc = await _inscripcionRepo.inscribirme(widget.quiniela.id);
      if (mounted) {
        setState(() {
          _miInscripcion = insc;
          _procesandoInscripcion = false;
        });
        _mostrarDialogExito();
      }
    } on InscripcionDuplicadaException catch (e) {
      if (mounted) {
        setState(() => _procesandoInscripcion = false);
        _showSnackBar(e.message, ProganaColors.gold);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesandoInscripcion = false);
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

  // ===========================================================================
  // DIALOG ÉXITO MIDNIGHT (rediseño completo)
  // ===========================================================================

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
              // Ícono check dorado con glow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                  Icons.check_rounded,
                  color: ProganaColors.midnight,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡INSCRITO!',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 24,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Estás participando en',
                style: GoogleFonts.outfit(
                  color: ProganaColors.creamDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.quiniela.nombre,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: ProganaColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Prepárate para predecir el Mundial 2026 🏆',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: ProganaColors.creamDim,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProganaColors.gold,
                    foregroundColor: ProganaColors.midnight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 12,
                    shadowColor: ProganaColors.gold.withValues(alpha: 0.4),
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
      body: CustomScrollView(
        slivers: [
          // Header verde decorativo
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: _buildHeader(),
            ),
          ),

          // Stat pills
          SliverToBoxAdapter(child: _buildStatPills()),

          // Botón inscripción
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildBotonInscripcion(),
            ),
          ),

          // Section header partidos
          SliverToBoxAdapter(child: _buildPartidosHeader()),

          // Lista de partidos
          _buildPartidosList(),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER VERDE — Gradient + pattern + número gigante decorativo
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ProganaColors.emeraldDeep, ProganaColors.midnight3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay (oscurece hacia abajo)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ProganaColors.midnight.withValues(alpha: 0.3),
                  ProganaColors.midnight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

          // Pattern diagonal 45° sutil
          CustomPaint(
            size: Size.infinite,
            painter: _DiagonalPatternPainter(),
          ),

          // Número GIGANTE translúcido decorativo
          Positioned(
            top: 40,
            left: 16,
            child: Text(
              widget.quiniela.numeroDisplay,
              style: GoogleFonts.archivoBlack(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 72,
                height: 1,
                letterSpacing: -3,
              ),
            ),
          ),

          // Botón back
          Positioned(
            top: 12,
            left: 16,
            child: _buildBackButton(),
          ),

          // Sponsor
          Positioned(
            top: 16,
            right: 16,
            child: _buildSponsorLabel(),
          ),

          // Título + subtítulo
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.quiniela.nombre.toUpperCase(),
                  style: GoogleFonts.archivoBlack(
                    color: ProganaColors.cream,
                    fontSize: 20,
                    letterSpacing: -0.2,
                    height: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.quiniela.rangoDisplay} · MUNDIAL 2026',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.creamDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: ProganaColors.cream,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildSponsorLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PATROCINADOR',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.creamDim,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'CERVECERA MX',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STAT PILLS — Predichos / Puntos / Posición
  // ===========================================================================

  Widget _buildStatPills() {
    final predichos = _miInscripcion?.totalPredicciones ?? 0;
    final puntos = _miInscripcion?.puntosTotales ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatPill(predichos.toString(), 'Predichos')),
          const SizedBox(width: 8),
          Expanded(child: _buildStatPill(_formatPuntos(puntos), 'Puntos')),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatPill(
              _miInscripcion != null ? '#—' : '—',
              'Posición',
            ),
          ),
        ],
      ),
    );
  }

  String _formatPuntos(double puntos) {
    if (puntos == puntos.toInt()) return puntos.toInt().toString();
    return puntos.toStringAsFixed(1);
  }

  Widget _buildStatPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(
          color: ProganaColors.gold.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.gold,
              fontSize: 20,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTÓN INSCRIPCIÓN — 4 estados (preservado del Día 4, rediseñado Midnight)
  // ===========================================================================

  Widget _buildBotonInscripcion() {
    // Estado 1: Verificando
    if (_verificandoInscripcion) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: ProganaColors.midnight2,
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: ProganaColors.gold,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // Estado 2: Ya inscrito
    if (_miInscripcion != null) {
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
        child: Center(
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
                'INSCRITO',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado 3: Procesando
    if (_procesandoInscripcion) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: ProganaColors.gold.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: ProganaColors.midnight,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    // Estado 4: NO inscrito - botón funcional
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _inscribirme,
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
              'INSCRIBIRME',
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

  // ===========================================================================
  // PARTIDOS LIST
  // ===========================================================================

  Widget _buildPartidosHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PARTIDOS',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          FutureBuilder<List<Partido>>(
            future: _futurePartidos,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final cant = snapshot.data!.length;
              return Text(
                '$cant PARTIDOS',
                style: GoogleFonts.jetBrainsMono(
                  color: ProganaColors.gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartidosList() {
    return FutureBuilder<List<Partido>>(
      future: _futurePartidos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: ProganaColors.gold,
                  strokeWidth: 3,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorPartidos(snapshot.error),
          );
        }

        final partidos = snapshot.data ?? [];

        if (partidos.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyPartidos());
        }

        return SliverList.builder(
          itemCount: partidos.length,
          itemBuilder: (context, index) => _buildMatchRow(partidos[index]),
        );
      },
    );
  }

  Widget _buildMatchRow(Partido p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        child: Row(
          children: [
            _buildDayLabel(p),
            const SizedBox(width: 12),
            Expanded(child: _buildTeamsLabel(p)),
            const SizedBox(width: 8),
            _buildPredictionLabel(p),
          ],
        ),
      ),
    );
  }

  Widget _buildDayLabel(Partido p) {
    return Container(
      width: 48,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: ProganaColors.gold.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            p.fechaHora.day.toString(),
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 18,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _mesAbreviado(p.fechaHora.month),
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.gold,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsLabel(Partido p) {
    // Usa el modelo REAL: equipoLocal.emojiBandera, equipoLocal.codigo, etc.
    final local = p.equipoLocal;
    final visit = p.equipoVisit;

    final localFlag = local?.emojiBandera ?? '🏳️';
    final visitFlag = visit?.emojiBandera ?? '🏳️';
    final localCode = local?.codigo ?? 'TBD';
    final visitCode = visit?.codigo ?? 'TBD';

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$localFlag ',
            style: const TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: localCode,
            style: GoogleFonts.outfit(
              color: ProganaColors.cream,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '  vs  ',
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 10,
            ),
          ),
          TextSpan(
            text: '$visitFlag ',
            style: const TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: visitCode,
            style: GoogleFonts.outfit(
              color: ProganaColors.cream,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionLabel(Partido p) {
    // Si el partido ya finalizó y hay marcador, mostrarlo
    if (p.estado.yaFinalizo && p.golesLocal != null) {
      return Text(
        p.marcador,
        style: GoogleFonts.jetBrainsMono(
          color: ProganaColors.gold,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // Si está en juego
    if (p.estado == EstadoPartido.enJuego) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: ProganaColors.crimson,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          'EN VIVO',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.cream,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    // Si el usuario NO está inscrito o no hay predicción aún
    // (Fase 2 traerá las predicciones reales del usuario)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: _miInscripcion != null
              ? ProganaColors.gold.withValues(alpha: 0.5)
              : ProganaColors.creamDim.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _miInscripcion != null ? 'SIN PRED' : 'PENDIENTE',
        style: GoogleFonts.jetBrainsMono(
          color: _miInscripcion != null
              ? ProganaColors.gold
              : ProganaColors.creamDim,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ===========================================================================
  // ESTADOS EMPTY / ERROR
  // ===========================================================================

  Widget _buildEmptyPartidos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Opacity(
              opacity: 0.3,
              child: Text('⚽', style: GoogleFonts.outfit(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'SIN PARTIDOS AÚN',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.cream,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los partidos de esta quiniela aparecerán aquí pronto.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ProganaColors.creamDim,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPartidos(Object? error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ProganaColors.crimson.withValues(alpha: 0.1),
              border: Border.all(color: ProganaColors.crimson),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'ERROR CARGANDO PARTIDOS',
                  style: GoogleFonts.archivoBlack(
                    color: ProganaColors.crimson,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error?.toString() ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: ProganaColors.creamDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cargarPartidos,
            style: ElevatedButton.styleFrom(
              backgroundColor: ProganaColors.gold,
              foregroundColor: ProganaColors.midnight,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
            ),
            child: Text(
              'REINTENTAR',
              style: GoogleFonts.archivoBlack(
                fontSize: 11,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mesAbreviado(int mes) {
    const meses = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return meses[mes];
  }
}

// =============================================================================
// CUSTOM PAINTER — Pattern diagonal 45° sutil en el header
// =============================================================================

class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 8;

    const spacing = 16.0;
    final diagonal = size.width + size.height;

    for (double i = -size.height; i < diagonal; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}