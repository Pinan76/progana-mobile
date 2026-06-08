// =============================================================================
// PROGANA Fantasy — Lista Quinielas Screen (Midnight Stadium)
// =============================================================================
//
// L41 COMPLIANT (30 may 2026):
//   ✓ Usa QuinielaRepository.obtenerTodasQuinielas() existente
//   ✓ Navega a DetalleQuinielaScreen(quiniela: q) preservando flujo Día 4
//   ✓ Nombre clase ListaQuinielasScreen preservado (no rompe imports)
//   ✓ Cards inline (sin widget separado por simplicidad)
//   ✓ Compatible Flutter Web (sin dart:io)
//   ✓ .withValues(alpha:) consistente
//   ✓ Conteo de partidos vía query batch a partidos_quiniela
//
// REFACTOR VISUAL — MIDNIGHT STADIUM:
//   ✓ Fondo midnight (sin gris claro)
//   ✓ AppBar con back button + título Archivo Black cream
//   ✓ Header decorativo "QUINIELAS · MUNDIAL 2026"
//   ✓ Cards midnight2 con badge dorado + status pill
//   ✓ Card #9 (Gran Final) destacada con borde dorado
//   ✓ 4 estados: loading / success / empty / error
//   ✓ Pull-to-refresh dorado
//   ✓ Cero verde/blanco residual
//
// FIX DÍA 10 PM 8 JUN 2026 (Pre-Mundial):
//   ✓ _buildStatusPill: lógica hardcoded → q.statusLabel + q.statusColorKey (centralizado)
//   ✓ Helper _colorFromKey mapea string → ProganaColors (consistente con HomeScreen)
//   ✓ _mesAbreviado removido (lógica movida al modelo Quiniela)
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/quiniela.dart';
import '../repository/quiniela_repository.dart';
import 'detalle_quiniela_screen.dart';

class ListaQuinielasScreen extends StatefulWidget {
  const ListaQuinielasScreen({super.key});

  @override
  State<ListaQuinielasScreen> createState() => _ListaQuinielasScreenState();
}

class _ListaQuinielasScreenState extends State<ListaQuinielasScreen> {
  final _repository = QuinielaRepository();
  late Future<_QuinielasListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<_QuinielasListData> _loadData() async {
    // 1. Cargar todas las quinielas (usa repository existente)
    final quinielas = await _repository.obtenerTodasQuinielas();

    // 2. Query batch para contar partidos por quiniela
    final supabase = Supabase.instance.client;
    final partidosCount = <int, int>{};

    if (quinielas.isNotEmpty) {
      final ids = quinielas.map((q) => q.id).toList();
      final response = await supabase
          .from('partidos_quiniela')
          .select('quiniela_id')
          .inFilter('quiniela_id', ids);

      for (final row in response as List) {
        final qId = (row as Map)['quiniela_id'] as int;
        partidosCount[qId] = (partidosCount[qId] ?? 0) + 1;
      }
    }

    return _QuinielasListData(
      quinielas: quinielas,
      partidosCount: partidosCount,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  void _handleQuinielaTap(Quiniela q) {
    // Navegación preservada del Día 4
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleQuinielaScreen(quiniela: q),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProganaColors.midnight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // APP BAR Midnight (con back button)
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
          // Back button
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
            'TODAS LAS QUINIELAS',
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
  // HEADER — Decorativo
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ProganaColors.gold.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'QUINIELAS',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MUNDIAL 2026 · 🇲🇽 🇺🇸 🇨🇦',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BODY — FutureBuilder con 4 estados
  // ===========================================================================

  Widget _buildBody() {
    return FutureBuilder<_QuinielasListData>(
      future: _future,
      builder: (context, snapshot) {
        // ESTADO: LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // ESTADO: ERROR
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        // ESTADO: SUCCESS (con o sin datos)
        final data = snapshot.data;
        if (data == null || data.quinielas.isEmpty) {
          return _buildEmptyState();
        }

        // ESTADO: SUCCESS con datos
        return _buildSuccessState(data);
      },
    );
  }

  // ===========================================================================
  // ESTADO: LOADING (skeleton cards shimmer)
  // ===========================================================================

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          _ShimmerBox(width: 36, height: 36, radius: 8),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 10, radius: 4),
                SizedBox(height: 6),
                _ShimmerBox(width: 120, height: 8, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 8),
          _ShimmerBox(width: 60, height: 22, radius: 4),
        ],
      ),
    );
  }

  // ===========================================================================
  // ESTADO: SUCCESS (lista de quinielas)
  // ===========================================================================

  Widget _buildSuccessState(_QuinielasListData data) {
    return RefreshIndicator(
      color: ProganaColors.gold,
      backgroundColor: ProganaColors.midnight2,
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.quinielas.length,
        itemBuilder: (context, index) {
          final q = data.quinielas[index];
          final totalPartidos = data.partidosCount[q.id] ?? 0;
          final esGranFinal = q.numeroOrden == 9;

          return _buildQuinielaCard(
            quiniela: q,
            totalPartidos: totalPartidos,
            destacada: esGranFinal,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // QUINIELA CARD — Inline (sin widget separado)
  // ===========================================================================

  Widget _buildQuinielaCard({
    required Quiniela quiniela,
    required int totalPartidos,
    required bool destacada,
  }) {
    return GestureDetector(
      onTap: () => _handleQuinielaTap(quiniela),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: destacada
              ? ProganaColors.gold.withValues(alpha: 0.08)
              : ProganaColors.midnight2,
          border: Border.all(
            color: destacada
                ? ProganaColors.gold
                : Colors.white.withValues(alpha: 0.04),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildNumberBadge(quiniela, destacada),
            const SizedBox(width: 12),
            Expanded(child: _buildCardInfo(quiniela, totalPartidos, destacada)),
            const SizedBox(width: 8),
            _buildStatusPill(quiniela),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBadge(Quiniela quiniela, bool destacada) {
    if (destacada) {
      // Gran Final: badge dorado sólido
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ProganaColors.gold, ProganaColors.goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          quiniela.numeroDisplay,
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.midnight,
            fontSize: 14,
          ),
        ),
      );
    }

    // Normal: badge con gradient dorado sutil
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProganaColors.gold.withValues(alpha: 0.2),
            ProganaColors.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ProganaColors.gold.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        quiniela.numeroDisplay,
        style: GoogleFonts.archivoBlack(
          color: ProganaColors.gold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCardInfo(Quiniela quiniela, int totalPartidos, bool destacada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          quiniela.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: destacada ? ProganaColors.gold : ProganaColors.cream,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$totalPartidos PARTIDOS · ${quiniela.rangoDisplay}',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.creamDim,
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// FIX DÍA 10 PM (8 jun 2026): Usa quiniela.statusLabel + statusColorKey
  /// Single source of truth en modelo Quiniela (compartido con HomeScreen)
  Widget _buildStatusPill(Quiniela quiniela) {
    final color = _colorFromKey(quiniela.statusColorKey);
    final label = quiniela.statusLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// FIX DÍA 10 PM (8 jun 2026): Mapping string key → ProganaColors
  Color _colorFromKey(String key) {
    switch (key) {
      case 'crimson':
        return ProganaColors.crimson;
      case 'emerald':
        return ProganaColors.emerald;
      case 'gold':
        return ProganaColors.gold;
      case 'grey':
      default:
        return ProganaColors.grey;
    }
  }

  // ===========================================================================
  // ESTADO: EMPTY
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.3,
              child: Text(
                '🏆',
                style: GoogleFonts.outfit(fontSize: 56),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SIN QUINIELAS ACTIVAS',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.cream,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El Mundial 2026 comienza el 11 de junio. Pronto verás todas las quinielas aquí.',
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

  // ===========================================================================
  // ESTADO: ERROR
  // ===========================================================================

  Widget _buildErrorState(Object? error) {
    String message = 'Error de conexión';
    if (error != null) {
      message = error.toString().replaceFirst('Exception: ', '');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ProganaColors.crimson.withValues(alpha: 0.1),
                border: Border.all(color: ProganaColors.crimson),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
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
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: ProganaColors.creamDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProganaColors.gold,
                foregroundColor: ProganaColors.midnight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'REINTENTAR',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.midnight,
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
}

// =============================================================================
// DATA HOLDER — Quinielas + conteo de partidos
// =============================================================================

class _QuinielasListData {
  final List<Quiniela> quinielas;
  final Map<int, int> partidosCount;

  _QuinielasListData({
    required this.quinielas,
    required this.partidosCount,
  });
}

// =============================================================================
// SHIMMER BOX — Skeleton animado
// =============================================================================

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: const [
                ProganaColors.midnight2,
                ProganaColors.midnight3,
                ProganaColors.midnight2,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}