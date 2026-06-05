// =============================================================================
// PROGANA Fantasy — RankingScreen (Ranking General)
// =============================================================================
//
// L41 COMPLIANT (4 jun 2026 - Día 9):
//   ✓ Header "Ranking General · MUNDIAL 2026 · ACUMULADO"
//   ✓ Podio top 3 (oro/plata/bronce) MOCK
//   ✓ Lista posiciones 4-N MOCK
//   ✓ Tu posición destacada (mock #147)
//   ✓ Disclaimer claro "Datos de muestra. Real al iniciar Mundial 11 jun"
//   ✓ Compatible Flutter Web (sin dart:io)
//
// Honestidad L41: este es PLACEHOLDER porque sin partidos jugados no hay puntos.
// Disclaimer hace transparente al sponsor que es mock.
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _userInitials = 'JP';
  String _userName = 'Tú';

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
  }

  Future<void> _loadUserInitials() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final email = user.email ?? 'usuario@progana.mx';
      final name = email.split('@').first;
      _userInitials = name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();

      try {
        final profile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          final fullName = profile['full_name'] as String?;
          if (fullName != null && fullName.isNotEmpty) {
            final parts = fullName.split(' ');
            _userInitials = parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : fullName.substring(0, 2).toUpperCase();
            _userName = 'Tú · ${parts[0]}';
          }
        }
      } catch (_) {}

      if (mounted) setState(() {});
    } catch (_) {}
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                    const SizedBox(height: 20),
                    _buildPodio(),
                    const SizedBox(height: 20),
                    _buildRankList(),
                  ],
                ),
              ),
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
  // DISCLAIMER (transparencia L41)
  // ===========================================================================

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(10),
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
              Icons.info_outline_rounded,
              color: ProganaColors.gold,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Datos de muestra. El ranking real iniciará el 11 de junio.',
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
    );
  }

  // ===========================================================================
  // PODIO TOP 3
  // ===========================================================================

  Widget _buildPodio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2do (plata)
          Expanded(
            child: _buildPodiumItem(
              rank: 2,
              initials: 'MR',
              name: 'M. Rodríguez',
              points: '142',
              color: const Color(0xFFC0C0C0), // Silver
              height: 100,
            ),
          ),
          const SizedBox(width: 8),
          // 1ro (oro)
          Expanded(
            child: _buildPodiumItem(
              rank: 1,
              initials: 'AC',
              name: 'A. Cruz',
              points: '156',
              color: ProganaColors.gold,
              height: 130,
            ),
          ),
          const SizedBox(width: 8),
          // 3ro (bronce)
          Expanded(
            child: _buildPodiumItem(
              rank: 3,
              initials: 'LV',
              name: 'L. Vázquez',
              points: '138',
              color: const Color(0xFFCD7F32), // Bronze
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String initials,
    required String name,
    required String points,
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
            initials,
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
            '$rank',
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
                name,
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
                '$points PTS',
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
  // RANK LIST (4-N) con TU posición destacada
  // ===========================================================================

  Widget _buildRankList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRankRow(
            pos: '04',
            initials: 'RT',
            name: 'R. Torres',
            pts: '132',
          ),
          _buildRankRow(
            pos: '05',
            initials: 'SG',
            name: 'S. García',
            pts: '128',
          ),
          _buildRankRow(
            pos: '06',
            initials: 'EM',
            name: 'E. Mendoza',
            pts: '125',
          ),
          // Separador "..."
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
          // TU posición destacada
          _buildRankRow(
            pos: '147',
            initials: _userInitials,
            name: _userName,
            pts: '0',
            isMe: true,
          ),
          _buildRankRow(
            pos: '148',
            initials: 'CM',
            name: 'C. Méndez',
            pts: '0',
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow({
    required String pos,
    required String initials,
    required String name,
    required String pts,
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
          // Position
          SizedBox(
            width: 32,
            child: Text(
              pos,
              style: GoogleFonts.archivoBlack(
                color: isMe ? ProganaColors.gold : ProganaColors.creamDim,
                fontSize: 13,
              ),
            ),
          ),
          // Mini avatar
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
              initials,
              style: GoogleFonts.archivoBlack(
                color: isMe ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.outfit(
                color: isMe ? ProganaColors.gold : ProganaColors.cream,
                fontSize: 12,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Points
          Text(
            pts,
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
}