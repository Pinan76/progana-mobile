// =============================================================================
// PROGANA Fantasy — PredictCard Widget
// =============================================================================
//
// L41 COMPLIANT (16 jun 2026):
//   ✓ Tarjeta IA dentro de pantalla predict_marcador
//   ✓ Diseño Midnight Stadium (consistente con app)
//   ✓ Endpoint /predictions (cuotas API-Football) vía PredictRepository
//   ✓ Display español vía NationDisplay (código FIFA → "México")
//   ✓ FAILSAFE: si Predict no responde → widget invisible (SizedBox.shrink)
//   ✓ Auto-load en initState
//   ✓ Loading state sutil (no bloquea UX)
//   ✓ Honestidad L41: badge ~59% + "IA sugiere, tú decides"
//
// Marca PROGANA: precisión real, NUNCA promete 90%.
//
// NOMBRES:
//   - home/away: nombre INGLÉS que entiende el motor (de Equipo.nombre)
//   - homeCode/awayCode: código FIFA (de Equipo.codigo) para display español
//   - El motor devuelve pick_team en inglés → se traduce con NationDisplay
//
// =============================================================================

library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/prediction_result.dart';
import '../repository/predict_repository.dart';
import '../utils/nation_display.dart';

class PredictCard extends StatefulWidget {
  /// Nombre equipo local en INGLÉS (ej. "Mexico") — lo que entiende el motor
  final String home;

  /// Nombre equipo visitante en INGLÉS (ej. "Brazil")
  final String away;

  /// Código FIFA del local (ej. "MEX") — para display español
  final String? homeCode;

  /// Código FIFA del visitante (ej. "BRA")
  final String? awayCode;

  const PredictCard({
    super.key,
    required this.home,
    required this.away,
    this.homeCode,
    this.awayCode,
  });

  @override
  State<PredictCard> createState() => _PredictCardState();
}

class _PredictCardState extends State<PredictCard>
    with SingleTickerProviderStateMixin {
  final _repo = PredictRepository();

  late Future<PredictionResult?> _future;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _future = _loadPrediction();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // NO llamamos _repo.dispose(): es singleton compartido entre PredictCards
    super.dispose();
  }

  Future<PredictionResult?> _loadPrediction() async {
    final result = await _repo.obtenerPrediccion(
      home: widget.home,
      away: widget.away,
    );

    if (result != null && mounted) {
      _fadeController.forward();
    }

    return result;
  }

  // ===========================================================================
  // HELPERS DISPLAY ESPAÑOL
  // ===========================================================================

  /// Traduce el pick_team del motor (inglés) a español.
  /// Prioriza match por código si coincide con home/away.
  String _pickTeamEs(PredictionResult p) {
    // Si el pick_team coincide con el home, usar homeCode; si con away, awayCode
    final pickEn = p.pickTeam;
    if (_mismoEquipo(pickEn, widget.home) && widget.homeCode != null) {
      return NationDisplay.fromCode(widget.homeCode, fallback: pickEn);
    }
    if (_mismoEquipo(pickEn, widget.away) && widget.awayCode != null) {
      return NationDisplay.fromCode(widget.awayCode, fallback: pickEn);
    }
    // Fallback: traducir por nombre inglés
    return NationDisplay.fromEnglish(pickEn, fallback: pickEn);
  }

  bool _mismoEquipo(String a, String b) {
    return a.toLowerCase().trim() == b.toLowerCase().trim();
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PredictionResult?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // L41 FAILSAFE: si null o error → widget invisible
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildSuccessState(snapshot.data!),
        );
      },
    );
  }

  // ===========================================================================
  // ESTADO: LOADING (skeleton sutil)
  // ===========================================================================

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        borderRadius: ProganaRadius.card,
        border: Border.all(color: ProganaColors.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: ProganaColors.gold.withValues(alpha: 0.4),
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CARGANDO ANÁLISIS IA…',
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

  // ===========================================================================
  // ESTADO: SUCCESS (la tarjeta completa)
  // ===========================================================================

  Widget _buildSuccessState(PredictionResult prediction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        borderRadius: ProganaRadius.card,
        border: Border.all(color: ProganaColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(prediction),
          const SizedBox(height: 14),
          _buildProbBar(prediction),
          const SizedBox(height: 12),
          _buildSugerencia(prediction),
          const SizedBox(height: 10),
          _buildJustificacion(prediction),
          const SizedBox(height: 10),
          _buildDisclaimer(prediction),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER: ícono IA + título + badge precisión
  // ===========================================================================

  Widget _buildHeader(PredictionResult prediction) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ProganaColors.gold.withValues(alpha: 0.15),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.psychology_outlined,
            color: ProganaColors.gold,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'PROGANA PREDICT IA',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ProganaColors.emerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            prediction.accuracyDisplay,
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.emerald,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BARRA L/E/V (probabilidades visuales)
  // ===========================================================================

  Widget _buildProbBar(PredictionResult prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Flexible(
                  flex: (prediction.localPct * 1000).round(),
                  child: Container(color: ProganaColors.emerald),
                ),
                Flexible(
                  flex: (prediction.empatePct * 1000).round(),
                  child: Container(color: ProganaColors.creamDim),
                ),
                Flexible(
                  flex: (prediction.visitaPct * 1000).round(),
                  child: Container(color: ProganaColors.gold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProbLabel('L', prediction.localPctStr, ProganaColors.emerald),
            _buildProbLabel('E', prediction.empatePctStr, ProganaColors.creamDim),
            _buildProbLabel('V', prediction.visitaPctStr, ProganaColors.gold),
          ],
        ),
      ],
    );
  }

  Widget _buildProbLabel(String letra, String porcentaje, Color color) {
    return Text(
      '$letra $porcentaje',
      style: GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  // ===========================================================================
  // SUGERENCIA: equipo (español) + L/E/V + marcador probable
  // ===========================================================================

  Widget _buildSugerencia(PredictionResult prediction) {
    final pickTeamEs = _pickTeamEs(prediction);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ProganaColors.midnight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUGERENCIA',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.creamDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pickTeamEs.toUpperCase()} · ${prediction.pick}',
                  style: GoogleFonts.archivoBlack(
                    color: prediction.pickColor,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (prediction.mostLikelyScore != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MARCADOR PROB.',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.creamDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prediction.scoreDisplay,
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.cream,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // JUSTIFICACIÓN (texto corto del backend)
  // ===========================================================================

  Widget _buildJustificacion(PredictionResult prediction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        prediction.justification,
        style: GoogleFonts.outfit(
          color: ProganaColors.creamDim,
          fontSize: 11,
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ===========================================================================
  // DISCLAIMER L41 BRUTAL HONEST
  // ===========================================================================

  Widget _buildDisclaimer(PredictionResult prediction) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ProganaColors.emerald.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: ProganaColors.emerald.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            color: ProganaColors.emerald,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  color: ProganaColors.creamDim,
                  fontSize: 10,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text:
                        'Precisión histórica ${prediction.accuracyDisplay} (al nivel del mercado). ',
                  ),
                  TextSpan(
                    text: 'La IA sugiere, tú decides.',
                    style: GoogleFonts.outfit(
                      color: ProganaColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}