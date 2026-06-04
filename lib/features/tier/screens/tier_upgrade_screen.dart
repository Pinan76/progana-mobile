// =============================================================================
// PROGANA Fantasy — TierUpgradeScreen (Comparar Planes)
// =============================================================================
//
// L41 COMPLIANT (3 jun 2026 - Día 8 PM):
//   ✓ 3 cards: Free / Plus / Pro
//   ✓ Plus tiene ribbon "RECOMENDADO" dorado diagonal (mi recomendación L41)
//   ✓ Pro sin ribbon, pero con gradient gold+crimson + sombra dorada
//   ✓ Features alineadas con Reglamento v1.2:
//     - Free: L/E/V + Ranking público (durante Mundial)
//     - Plus: Marcador (3pts) + Goleador + Sin pub + IA
//     - Pro: Todo de Plus + CREAR quinielas privadas + Badge
//   ✓ Detecta tier actual del user → muestra "PLAN ACTUAL" en card correspondiente
//   ✓ Botones Upgrade → SnackBar (Stripe pendiente post-demo)
//   ✓ Compatible Flutter Web (sin dart:io)
//   ✓ .withValues(alpha:) consistente
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';

class TierUpgradeScreen extends StatefulWidget {
  const TierUpgradeScreen({super.key});

  @override
  State<TierUpgradeScreen> createState() => _TierUpgradeScreenState();
}

class _TierUpgradeScreenState extends State<TierUpgradeScreen> {
  String _tierActual = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('tier')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _tierActual = (profile?['tier'] as String?) ?? 'free';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleUpgrade(String targetTier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pago disponible próximamente. Estamos en pruebas técnicas.',
          style: GoogleFonts.outfit(
            color: ProganaColors.cream,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: ProganaColors.midnight3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ProganaColors.gold,
                        strokeWidth: 3,
                      ),
                    )
                  : _buildContent(),
            ),
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
            'PLANES',
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
  // CONTENT
  // ===========================================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Título principal
          _buildHero(),
          const SizedBox(height: 32),

          // Card Free
          _buildFreeCard(),
          const SizedBox(height: 12),

          // Card Plus (con ribbon RECOMENDADO)
          _buildPlusCard(),
          const SizedBox(height: 12),

          // Card Pro
          _buildProCard(),
          const SizedBox(height: 24),

          // Footer disclaimer
          _buildFooterDisclaimer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'SUBE DE ',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 28,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'NIVEL',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.gold,
                  fontSize: 28,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'DESBLOQUEA TODO EL POTENCIAL',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.creamDim,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CARD FREE
  // ===========================================================================

  Widget _buildFreeCard() {
    final isActual = _tierActual == 'free';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'FREE',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.creamDim,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          _buildPrice(currency: '\$', amount: '0', period: '/ mes'),
          const SizedBox(height: 14),

          // Features
          _buildFeature('Predicción L / E / V', isGold: false),
          _buildFeature('Ranking público del Mundial', isGold: false),
          _buildFeature('Gratis durante Mundial 2026', isGold: false),
          const SizedBox(height: 14),

          // Button
          _buildTierButton(
            label: isActual ? 'PLAN ACTUAL' : 'PLAN GRATIS',
            isActual: isActual,
            type: TierBtnType.free,
            onTap: isActual ? null : () => _handleUpgrade('free'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD PLUS (con ribbon RECOMENDADO)
  // ===========================================================================

  Widget _buildPlusCard() {
    final isActual = _tierActual == 'plus';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ProganaColors.emerald.withValues(alpha: 0.08),
                ProganaColors.emerald.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: ProganaColors.emerald, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLUS',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.emerald,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              _buildPrice(currency: '\$', amount: '25', period: 'MXN / mes'),
              const SizedBox(height: 14),
              _buildFeature('Marcador exacto (3 pts)', isGold: false),
              _buildFeature('Predicción goleador (+1 pt)', isGold: false),
              _buildFeature('Sin publicidad', isGold: false),
              _buildFeature('PROGANA Predict (IA)', isGold: false),
              _buildFeature('Acceso oficial post-Mundial', isGold: false),
              const SizedBox(height: 14),
              _buildTierButton(
                label: isActual ? 'PLAN ACTUAL' : 'SUBIR A PLUS',
                isActual: isActual,
                type: TierBtnType.plus,
                onTap: isActual ? null : () => _handleUpgrade('plus'),
              ),
            ],
          ),
        ),

        // Ribbon RECOMENDADO diagonal (Plus)
        Positioned(
          top: 12,
          right: -28,
          child: Transform.rotate(
            angle: 0.785, // 45°
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 3),
              color: ProganaColors.gold,
              child: Text(
                'RECOMENDADO',
                style: GoogleFonts.jetBrainsMono(
                  color: ProganaColors.midnight,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CARD PRO
  // ===========================================================================

  Widget _buildProCard() {
    final isActual = _tierActual == 'pro';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProganaColors.gold.withValues(alpha: 0.15),
            ProganaColors.crimson.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ProganaColors.gold, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ProganaColors.gold.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRO',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.gold,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          _buildPrice(currency: '\$', amount: '49.99', period: 'MXN / mes'),
          const SizedBox(height: 14),
          _buildFeature('Todo lo de Plus', isGold: false),
          _buildFeature('CREAR quinielas privadas', isGold: true, icon: '★'),
          _buildFeature('Para grupos cerrados (peñas, oficinas)',
              isGold: true, icon: '★'),
          _buildFeature('Modelo "Polla Mexicana"',
              isGold: true, icon: '★'),
          _buildFeature('Badge Pro distintivo', isGold: true, icon: '★'),
          const SizedBox(height: 14),
          _buildTierButton(
            label: isActual ? 'PLAN ACTUAL' : 'SUBIR A PRO',
            isActual: isActual,
            type: TierBtnType.pro,
            onTap: isActual ? null : () => _handleUpgrade('pro'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED WIDGETS
  // ===========================================================================

  Widget _buildPrice({
    required String currency,
    required String amount,
    required String period,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          currency,
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.creamDim,
            fontSize: 14,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          amount,
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.cream,
            fontSize: 32,
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            period,
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String text, {required bool isGold, String icon = '✓'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: isGold ? ProganaColors.gold : ProganaColors.emerald,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: isGold ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 11,
                fontWeight: isGold ? FontWeight.w700 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierButton({
    required String label,
    required bool isActual,
    required TierBtnType type,
    required VoidCallback? onTap,
  }) {
    Color bg;
    Color fg;
    Color? borderColor;
    BoxShadow? shadow;

    if (isActual) {
      // Plan actual: estilo "selected"
      switch (type) {
        case TierBtnType.free:
          bg = Colors.transparent;
          fg = ProganaColors.creamDim;
          borderColor = Colors.white.withValues(alpha: 0.1);
          break;
        case TierBtnType.plus:
          bg = ProganaColors.emerald.withValues(alpha: 0.2);
          fg = ProganaColors.emerald;
          borderColor = ProganaColors.emerald;
          break;
        case TierBtnType.pro:
          bg = ProganaColors.gold.withValues(alpha: 0.2);
          fg = ProganaColors.gold;
          borderColor = ProganaColors.gold;
          break;
      }
    } else {
      // No es actual: estilo "call to action"
      switch (type) {
        case TierBtnType.free:
          bg = Colors.transparent;
          fg = ProganaColors.creamDim;
          borderColor = Colors.white.withValues(alpha: 0.1);
          break;
        case TierBtnType.plus:
          bg = ProganaColors.emerald;
          fg = ProganaColors.midnight;
          shadow = BoxShadow(
            color: ProganaColors.emerald.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          );
          break;
        case TierBtnType.pro:
          bg = ProganaColors.gold;
          fg = ProganaColors.midnight;
          shadow = BoxShadow(
            color: ProganaColors.gold.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          );
          break;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            border: borderColor != null
                ? Border.all(color: borderColor)
                : null,
            borderRadius: BorderRadius.circular(8),
            boxShadow: shadow != null ? [shadow] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.archivoBlack(
              color: fg,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FOOTER DISCLAIMER
  // ===========================================================================

  Widget _buildFooterDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            'Cancela cuando quieras. Sin compromiso.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Concurso de habilidad · No requiere SEGOB · 18+',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tipos de botón tier (para styling)
enum TierBtnType { free, plus, pro }