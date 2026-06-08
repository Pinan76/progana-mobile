// =============================================================================
// PROGANA Fantasy — RankingScreen (Ranking General)
// =============================================================================
//
// L41 COMPLIANT (4 jun 2026 - Día 9):
//   ✓ Header "Ranking General · MUNDIAL 2026 · ACUMULADO"
//   ✓ Podio top 3 (oro/plata/bronce)
//   ✓ Lista posiciones 4-N
//   ✓ Tu posición destacada
//   ✓ Compatible Flutter Web (sin dart:io)
//
// REFACTOR DÍA 10 PM 8 JUN 2026 (Pre-Mundial):
//   ✓ Mock → datos reales desde matview rankings_general
//   ✓ RankingRepository + RankingEntry integrados
//   ✓ FutureBuilder con 4 estados: loading / error / empty / success
//   ✓ Estado vacío Opción A.1: CTA con conteo quinielas abiertas
//   ✓ Botón "VER QUINIELAS" → navega ListaQuinielasScreen
//   ✓ Disclaimer mock eliminado (BD es la verdad ahora)
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/ranking_entry.dart';
import '../repository/ranking_repository.dart';
import '../../quinielas/screens/lista_quinielas_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _rankingRepo = RankingRepository();
  final _supabase = Supabase.instance.client;

  late Future<_RankingData> _future;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id ?? '';
    _future = _loadData();
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<_RankingData> _loadData() async {
    // 1. Cargar ranking general (top 100)
    final ranking = await _rankingRepo.obtenerRankingGeneral(limit: 100);

    // 2. Si user está en ranking, ya viene en la lista. Si NO está, query separado.
    RankingEntry? miPosicion;
    final yaEnTop100 = ranking.any((e) => e.userId == _userId);
    if (!yaEnTop100 && _userId.isNotEmpty) {
      miPosicion = await _rankingRepo.obtenerMiPosicionGeneral();
    }

    // 3. Conteo de quinielas abiertas (CTA estado vacío)
    int quinielasAbiertas = 0;
    if (ranking.isEmpty) {
      try {
        final response = await _supabase
            .from('quinielas')
            .select('id')
            .eq('estado', 'inscripcion');
        quinielasAbiertas = (response as List).length;
      } catch (_) {
        // Si falla query, deja 0 (CTA mostrará mensaje genérico)
      }
    }

    return _RankingData(
      ranking: ranking,
      miPosicion: miPosicion,
      quinielasAbiertas: quinielasAbiertas,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  void _navigateToQuinielas() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const ListaQuinielasScreen()),
        )
        .then((_) {
      // Recargar al volver (por si user se inscribió)
      if (mounted) _handleRefresh();
    });
  }

  // ===========================================================================
  // BUILD PRINCIPAL
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
            'RANKING',
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
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Text(
            'RANKING GENERAL',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MUNDIAL 2026 · ACUMULADO',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
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
    return FutureBuilder<_RankingData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final data = snapshot.data;
        if (data == null || data.ranking.isEmpty) {
          return _buildEmptyState(data?.quinielasAbiertas ?? 0);
        }

        return _buildSuccessState(data);
      },
    );
  }

  // ===========================================================================
  // ESTADO: LOADING
  // ===========================================================================

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: ProganaColors.gold,
        strokeWidth: 3,
      ),
    );
  }

  // ===========================================================================
  // ESTADO: EMPTY (Opción A.1 — con CTA)
  // ===========================================================================

  Widget _buildEmptyState(int quinielasAbiertas) {
    return RefreshIndicator(
      color: ProganaColors.gold,
      backgroundColor: ProganaColors.midnight2,
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          // Trofeo grande
          Center(
            child: Opacity(
              opacity: 0.3,
              child: Text(
                '🏆',
                style: GoogleFonts.outfit(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Título principal
          Text(
            'EL RANKING ARRANCA EL 11 DE JUNIO',
            textAlign: TextAlign.center,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Subtítulo
          Text(
            'Después del primer partido del Mundial,\naparecerás aquí con tus puntos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Card CTA con conteo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProganaColors.midnight2,
              border: Border.all(
                color: ProganaColors.emerald.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      quinielasAbiertas > 0
                          ? '$quinielasAbiertas QUINIELA${quinielasAbiertas == 1 ? '' : 'S'} ABIERTA${quinielasAbiertas == 1 ? '' : 'S'}'
                          : 'INSCRÍBETE A LAS QUINIELAS',
                      style: GoogleFonts.jetBrainsMono(
                        color: ProganaColors.emerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Inscríbete para competir y aparecer en el ranking real',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: ProganaColors.creamDim,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botón principal
          ElevatedButton(
            onPressed: _navigateToQuinielas,
            style: ElevatedButton.styleFrom(
              backgroundColor: ProganaColors.gold,
              foregroundColor: ProganaColors.midnight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'VER QUINIELAS →',
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.midnight,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ESTADO: ERROR
  // ===========================================================================

  Widget _buildErrorState(Object? error) {
    final message = error != null
        ? error.toString().replaceFirst('Exception: ', '')
        : 'Error desconocido';

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
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ProganaColors.creamDim,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProganaColors.gold,
                foregroundColor: ProganaColors.midnight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      ),
    );
  }

  // ===========================================================================
  // ESTADO: SUCCESS (datos reales)
  // ===========================================================================

  Widget _buildSuccessState(_RankingData data) {
    final ranking = data.ranking;
    final miPosicion = data.miPosicion;

    // Top 3 → podio
    final top3 = ranking.take(3).toList();

    // 4-N → lista
    final resto = ranking.length > 3 ? ranking.skip(3).toList() : <RankingEntry>[];

    return RefreshIndicator(
      color: ProganaColors.gold,
      backgroundColor: ProganaColors.midnight2,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Podio top 3
            if (top3.isNotEmpty) _buildPodio(top3),
            const SizedBox(height: 20),
            // Lista 4-N
            if (resto.isNotEmpty) _buildRankList(resto),
            // Tu posición separada (si no estás en top 100)
            if (miPosicion != null) _buildMiPosicionExtra(miPosicion),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PODIO TOP 3 (datos reales)
  // ===========================================================================

  Widget _buildPodio(List<RankingEntry> top3) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2do (plata)
          Expanded(
            child: top3.length >= 2
                ? _buildPodiumItem(
                    entry: top3[1],
                    color: const Color(0xFFC0C0C0),
                    height: 100,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          // 1ro (oro)
          Expanded(
            child: _buildPodiumItem(
              entry: top3[0],
              color: ProganaColors.gold,
              height: 130,
            ),
          ),
          const SizedBox(width: 8),
          // 3ro (bronce)
          Expanded(
            child: top3.length >= 3
                ? _buildPodiumItem(
                    entry: top3[2],
                    color: const Color(0xFFCD7F32),
                    height: 80,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required RankingEntry entry,
    required Color color,
    required double height,
  }) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ProganaColors.midnight2,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            entry.iniciales,
            style: GoogleFonts.archivoBlack(
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Rank number
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          alignment: Alignment.center,
          child: Text(
            '${entry.posicion}',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.midnight,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Block
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                style: GoogleFonts.outfit(
                  color: ProganaColors.cream,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.puntosDisplay} PTS',
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // RANK LIST (4-N) con tu posición destacada
  // ===========================================================================

  Widget _buildRankList(List<RankingEntry> entries) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: entries.map((entry) {
          final isMe = entry.userId == _userId;
          return _buildRankRow(entry: entry, isMe: isMe);
        }).toList(),
      ),
    );
  }

  Widget _buildRankRow({
    required RankingEntry entry,
    bool isMe = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? ProganaColors.gold.withValues(alpha: 0.1)
            : ProganaColors.midnight2,
        border: Border.all(
          color: isMe
              ? ProganaColors.gold
              : Colors.white.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.posicion.toString().padLeft(2, '0'),
              style: GoogleFonts.archivoBlack(
                color: isMe ? ProganaColors.gold : ProganaColors.creamDim,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? ProganaColors.gold.withValues(alpha: 0.2)
                  : ProganaColors.midnight3,
              border: Border.all(
                color: isMe
                    ? ProganaColors.gold
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.iniciales,
              style: GoogleFonts.archivoBlack(
                color: isMe ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? 'Tú · ${entry.displayName}' : entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: isMe ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 12,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            entry.puntosDisplay,
            style: GoogleFonts.jetBrainsMono(
              color: isMe ? ProganaColors.gold : ProganaColors.cream,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'PTS',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TU POSICIÓN extra (si no estás en top 100)
  // ===========================================================================

  Widget _buildMiPosicionExtra(RankingEntry miPosicion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Separador
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '· · ·',
              style: GoogleFonts.jetBrainsMono(
                color: ProganaColors.creamDim,
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
          ),
          // Tu posición destacada
          _buildRankRow(entry: miPosicion, isMe: true),
        ],
      ),
    );
  }
}

// =============================================================================
// DATA HOLDER
// =============================================================================

class _RankingData {
  final List<RankingEntry> ranking;
  final RankingEntry? miPosicion;
  final int quinielasAbiertas;

  _RankingData({
    required this.ranking,
    this.miPosicion,
    required this.quinielasAbiertas,
  });
}