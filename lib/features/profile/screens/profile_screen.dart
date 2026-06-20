// =============================================================================
// PROGANA Fantasy — ProfileScreen (Mi Perfil)
// =============================================================================
//
// L41 COMPLIANT (17 jun 2026 - Mundial activo):
//   ✓ Avatar grande con iniciales reales del user
//   ✓ Nombre + handle (de profile/email)
//   ✓ Tier badge con corona dorada/emerald según tier real
//   ✓ Ranking display REAL (posición + puntos de rankings_general)
//   ✓ Stats grid REAL (EXACTOS / RESULTADO / CASI / FALLOS desde la BD)
//   ✓ Defensivo: si falla la consulta, muestra 0 sin romper el perfil
//   ✓ Botón logout en footer
//   ✓ Compatible Flutter Web (sin dart:io)
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  String _userName = 'Usuario';
  String _userHandle = '@usuario';
  String _userInitials = 'U';
  String _userTier = 'FREE';
  bool _isLoading = true;

  // Stats reales del Mundial (de rankings_general + puntos_partido)
  double _puntosTotales = 0;
  int _posicion = 0;
  int _exactos = 0;
  int _resultados = 0;
  int _casi = 0;
  int _fallos = 0;
  bool _tieneStats = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Defaults desde email
      final email = user.email ?? 'usuario@progana.mx';
      _userName = email.split('@').first;
      _userHandle = '@${_userName.toLowerCase()}';
      _userInitials = _userName.length >= 2
          ? _userName.substring(0, 2).toUpperCase()
          : _userName.toUpperCase();

      // Cargar profile completo
      try {
        final profile = await _supabase
            .from('profiles')
            .select('username, full_name, tier')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          final fullName = profile['full_name'] as String?;
          final username = profile['username'] as String?;

          if (fullName != null && fullName.isNotEmpty) {
            _userName = fullName;
            final parts = fullName.split(' ');
            _userInitials = parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : fullName.substring(0, 2).toUpperCase();
          }

          if (username != null && username.isNotEmpty) {
            _userHandle = '@$username';
          }

          _userTier = (profile['tier'] as String? ?? 'free').toUpperCase();
        }
      } catch (_) {
        // Si profile no existe, usar defaults
      }

      // Cargar stats del ranking (Mundial activo). Defensivo: si falla, quedan en 0.
      try {
        final stats = await _supabase
            .from('rankings_general')
            .select(
                'puntos_totales, total_exactos, total_resultado, total_casi, posicion')
            .eq('user_id', user.id)
            .maybeSingle();

        if (stats != null) {
          _puntosTotales = (stats['puntos_totales'] as num?)?.toDouble() ?? 0;
          _exactos = (stats['total_exactos'] as num?)?.toInt() ?? 0;
          _resultados = (stats['total_resultado'] as num?)?.toInt() ?? 0;
          _casi = (stats['total_casi'] as num?)?.toInt() ?? 0;
          _posicion = (stats['posicion'] as num?)?.toInt() ?? 0;
          _tieneStats = true;
        }
      } catch (_) {
        // Sin acceso al ranking aún: stats quedan en 0
      }

      // Contar fallos (de puntos_partido). Defensivo: si falla, queda en 0.
      try {
        final fallosRows = await _supabase
            .from('puntos_partido')
            .select('id')
            .eq('user_id', user.id)
            .eq('tipo_acierto', 'fallo');
        _fallos = (fallosRows as List).length;
      } catch (_) {
        // Sin acceso a puntos_partido: fallos queda en 0
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        // Pop hasta la raíz (que mostrará Splash o Login según auth state)
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: ProganaColors.crimson,
          ),
        );
      }
    }
  }

  // Formatea puntos: 10.5 -> "10.5", 7.0 -> "7"
  String _fmtPuntos(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
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
            ? const Center(
                child: CircularProgressIndicator(
                  color: ProganaColors.gold,
                  strokeWidth: 3,
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 24),
                _buildRankDisplay(),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 16),
                _buildPlaceholderDisclaimer(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
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
            'MI PERFIL',
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
  // HERO — Avatar + Nombre + Handle + Tier
  // ===========================================================================

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar grande dorado
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [ProganaColors.gold, ProganaColors.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: ProganaColors.goldBright,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: ProganaColors.gold.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _userInitials,
              style: GoogleFonts.archivoBlack(
                color: ProganaColors.midnight,
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nombre
          Text(
            _userName,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Handle
          Text(
            '$_userHandle · 2026',
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Tier badge con corona
          _buildTierBadge(),
        ],
      ),
    );
  }

  Widget _buildTierBadge() {
    Color color;
    String icon;
    switch (_userTier) {
      case 'PRO':
        color = ProganaColors.gold;
        icon = '👑';
        break;
      case 'PLUS':
        color = ProganaColors.emerald;
        icon = '⭐';
        break;
      default:
        color = ProganaColors.grey;
        icon = '🎟️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            _userTier,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RANK DISPLAY — posición + puntos reales
  // ===========================================================================

  Widget _buildRankDisplay() {
    // Si tiene stats: muestra posición real; si no: "—" (pre-Mundial / sin datos)
    final rankNum = _tieneStats && _posicion > 0 ? '$_posicion' : '—';
    final subtitle = _tieneStats
        ? 'Mundial 2026 en curso'
        : 'Aún sin predicciones registradas';
    final puntosTxt = _tieneStats ? _fmtPuntos(_puntosTotales) : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProganaColors.midnight2,
            ProganaColors.midnight3,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ProganaColors.gold.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank number
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rankNum,
                    style: GoogleFonts.archivoBlack(
                      color: ProganaColors.gold,
                      fontSize: 36,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '°',
                      style: GoogleFonts.archivoBlack(
                        color: ProganaColors.gold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RANKING GLOBAL',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.cream,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: ProganaColors.creamDim,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            children: [
              Text(
                puntosTxt,
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 22,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PTS',
                style: GoogleFonts.jetBrainsMono(
                  color: ProganaColors.creamDim,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATS GRID 2x2 — datos reales
  // ===========================================================================

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  num: '$_exactos',
                  label: 'EXACTOS',
                  color: ProganaColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  num: '$_resultados',
                  label: 'RESULTADO',
                  color: ProganaColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  num: '$_casi',
                  label: 'CASI',
                  color: ProganaColors.creamDim,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  num: '$_fallos',
                  label: 'FALLOS',
                  color: ProganaColors.crimson,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String num,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            num,
            style: GoogleFonts.archivoBlack(
              color: color,
              fontSize: 24,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: ProganaColors.creamDim,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DISCLAIMER (dinámico según si ya hay stats)
  // ===========================================================================

  Widget _buildPlaceholderDisclaimer() {
    final texto = _tieneStats
        ? 'Tus estadísticas se actualizan automáticamente conforme avanzan los partidos del Mundial 2026.'
        : 'Tus estadísticas se actualizarán en tiempo real durante el Mundial 2026.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
              Icons.info_outline_rounded,
              color: ProganaColors.gold,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: GoogleFonts.outfit(
                  color: ProganaColors.cream,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LOGOUT BUTTON
  // ===========================================================================

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _handleLogout,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: ProganaColors.crimson.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: ProganaColors.crimson,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'CERRAR SESIÓN',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.crimson,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
