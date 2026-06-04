// =============================================================================
// PROGANA Fantasy — HomeScreen (Feed Principal Midnight Stadium)
// =============================================================================
//
// L41 COMPLIANT (correcciones aplicadas 30 may 2026):
//   ✓ Imports correctos: repository/ singular + lista_quinielas_screen.dart
//   ✓ QuinielaRepository (singular)
//   ✓ obtenerTodasQuinielas() (no getAllQuinielas)
//   ✓ Exception genérico (no QuinielasException)
//   ✓ estado.etiqueta (no .label)
//   ✓ ListaQuinielasScreen (no QuinielasListScreen)
//   ✓ Sin dart:io (compatible Web)
//   ✓ .withValues(alpha:) consistente
//   ✓ Timer con dispose
//
// FASE 1 — Esqueleto Midnight Stadium con datos parcialmente reales:
//   ✓ Avatar + nombre + tier (reales si profiles existe)
//   ✓ Next Match Card con countdown HARDCODED (Fase 2: query real)
//   ✓ Equipos México vs Argentina HARDCODED (Fase 2: real)
//   ✓ Lista de quinielas REAL desde Supabase
//   ✓ Bottom nav funcional (HOME + QUINIELAS funcionan, RANKING + PERFIL placeholder)
//
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../../quinielas/models/quiniela.dart';
import '../../quinielas/repository/quiniela_repository.dart';
import '../../quinielas/screens/lista_quinielas_screen.dart';
import '../../tier/screens/tier_upgrade_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = QuinielaRepository();
  final _supabase = Supabase.instance.client;

  // === DATOS ===
  String _userName = 'Usuario';
  String _userInitials = '?';
  String _userTier = 'FREE';
  List<Quiniela> _misQuinielas = [];
  Map<int, int> _partidosCount = {};

  // === ESTADO ===
  bool _isLoading = true;
  String? _errorMessage;
  int _currentNavIndex = 0;

  // === COUNTDOWN ===
  Timer? _countdownTimer;
  Duration _timeRemaining = const Duration(hours: 2, minutes: 14, seconds: 33);

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Datos del usuario logueado
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Email como fallback
        final email = user.email ?? 'usuario@progana.mx';
        _userName = email.split('@').first;

        // Iniciales: primeras 2 letras del nombre
        _userInitials = _userName.length >= 2
            ? _userName.substring(0, 2).toUpperCase()
            : _userName.toUpperCase();

        // Tier del profile (si existe la tabla con esas columnas)
        try {
          final profile = await _supabase
              .from('profiles')
              .select('full_name, tier')
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            final fullName = profile['full_name'] as String?;
            if (fullName != null && fullName.isNotEmpty) {
              _userName = fullName;
              final parts = fullName.split(' ');
              _userInitials = parts.length >= 2
                  ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                  : fullName.substring(0, 2).toUpperCase();
            }
            final tier = profile['tier'] as String?;
            if (tier != null) {
              _userTier = tier.toUpperCase();
            }
          }
        } catch (_) {
          // Profile o columnas no existen, usar defaults
        }
      }

      // 2. Quinielas del Mundial
      final quinielas = await _repo.obtenerTodasQuinielas();

      // 3. Conteo de partidos por quiniela (batch query)
      final Map<int, int> partidosCount = {};
      if (quinielas.isNotEmpty) {
        final ids = quinielas.map((q) => q.id).toList();
        final response = await _supabase
            .from('partidos_quiniela')
            .select('quiniela_id')
            .inFilter('quiniela_id', ids);

        for (final row in response as List) {
          final qId = (row as Map)['quiniela_id'] as int;
          partidosCount[qId] = (partidosCount[qId] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _misQuinielas = quinielas;
          _partidosCount = partidosCount;
          _isLoading = false;
        });
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
  // COUNTDOWN LIVE (Fase 1: hardcoded, Fase 2: calculado desde fecha real)
  // ===========================================================================

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_timeRemaining.inSeconds > 0) {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        }
      });
    });
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _navigateToQuinielas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListaQuinielasScreen()),
    );
  }

  void _navigateToQuiniela(Quiniela q) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrir: ${q.nombre}'),
        backgroundColor: ProganaColors.midnight3,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO Fase 2: Navigator.push a DetalleQuinielaScreen(quiniela: q)
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);

    if (index == 1) {
      // Tab "QUINIELAS"
      _navigateToQuinielas();
      // Reset al volver
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
    } else if (index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tab ${_navLabel(index)} próximamente'),
          backgroundColor: ProganaColors.midnight3,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
    }
  }

  String _navLabel(int index) {
    switch (index) {
      case 0:
        return 'HOME';
      case 1:
        return 'QUINIELAS';
      case 2:
        return 'RANKING';
      case 3:
        return 'PERFIL';
      default:
        return '';
    }
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProganaColors.midnight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===========================================================================
  // HEADER — Avatar + nombre + tier badge
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ProganaColors.gold.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡HOLA!',
                  style: GoogleFonts.jetBrainsMono(
                    color: ProganaColors.creamDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: GoogleFonts.archivoBlack(
                    color: ProganaColors.cream,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildTierBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [ProganaColors.gold, ProganaColors.goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ProganaColors.goldBright,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ProganaColors.gold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _userInitials,
        style: GoogleFonts.archivoBlack(
          color: ProganaColors.midnight,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTierBadge() {
    // Color según tier
    Color color;
    switch (_userTier) {
      case 'PRO':
        color = ProganaColors.gold;
        break;
      case 'PLUS':
        color = ProganaColors.emerald;
        break;
      default:
        color = ProganaColors.grey;
    }

    return GestureDetector(
      onTap: _navigateToTierUpgrade,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _userTier,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 8,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NAVIGATE TO TIER UPGRADE
  // ===========================================================================

  Future<void> _navigateToTierUpgrade() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TierUpgradeScreen()),
    );
    // Recargar tier al volver (en caso de que upgrade)
    _loadData();
  }

  // ===========================================================================
  // BODY — loading / error / success
  // ===========================================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ProganaColors.gold,
          strokeWidth: 3,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: ProganaColors.gold,
      backgroundColor: ProganaColors.midnight2,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNextMatchCard(),
            _buildSectionHeader(),
            _buildQuinielasList(),
            const SizedBox(height: 24),
          ],
        ),
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
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProganaColors.gold,
                foregroundColor: ProganaColors.midnight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  // NEXT MATCH CARD — Card "PRÓXIMO PARTIDO" con countdown LIVE
  // ===========================================================================

  Widget _buildNextMatchCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProganaColors.midnight2, ProganaColors.midnight3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ProganaColors.gold.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Ribbon "PRÓXIMO PARTIDO" diagonal
            Positioned(
              top: 12,
              right: -42,
              child: Transform.rotate(
                angle: 0.785, // 45°
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 4,
                  ),
                  color: ProganaColors.gold,
                  child: Text(
                    'PRÓXIMO PARTIDO',
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

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: ProganaColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CIERRA EN ${_formatCountdown(_timeRemaining)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: ProganaColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Equipos
                  Row(
                    children: [
                      _buildTeamColumn('🇲🇽', 'MÉXICO'),
                      Text(
                        'VS',
                        style: GoogleFonts.archivoBlack(
                          color: ProganaColors.gold,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      _buildTeamColumn('🇦🇷', 'ARGENTINA'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: ProganaColors.gold.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),

                  // Meta info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '11 JUN · 14:00 CDMX',
                        style: GoogleFonts.jetBrainsMono(
                          color: ProganaColors.creamDim,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '▸ APERTURA',
                        style: GoogleFonts.jetBrainsMono(
                          color: ProganaColors.emerald,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String flag, String name) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 36,
            decoration: BoxDecoration(
              color: ProganaColors.midnight3,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(flag, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER — "TUS QUINIELAS" + "VER TODAS →"
  // ===========================================================================

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TUS QUINIELAS',
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          GestureDetector(
            onTap: _navigateToQuinielas,
            child: Text(
              'VER TODAS →',
              style: GoogleFonts.jetBrainsMono(
                color: ProganaColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUINIELAS LIST — Lista limitada (primeras 3)
  // ===========================================================================

  Widget _buildQuinielasList() {
    if (_misQuinielas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay quinielas activas',
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Mostrar solo las primeras 3 en Home (el resto en ListaQuinielasScreen)
    final quinielasParaMostrar = _misQuinielas.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: quinielasParaMostrar.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          final totalPartidos = _partidosCount[q.id] ?? 0;

          // Animación de entrada escalonada
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildQuinielaCardRow(q, totalPartidos),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuinielaCardRow(Quiniela q, int totalPartidos) {
    return GestureDetector(
      onTap: () => _navigateToQuiniela(q),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ProganaColors.midnight2,
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Número badge
            Container(
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
                q.numeroDisplay,
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.gold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: ProganaColors.cream,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalPartidos partidos · ${q.rangoDisplay}',
                    style: GoogleFonts.jetBrainsMono(
                      color: ProganaColors.creamDim,
                      fontSize: 8,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Status pill
            _buildStatusPill(q),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(Quiniela q) {
    Color color;
    String label;

    if (q.estaActivaAhora) {
      color = ProganaColors.crimson;
      label = 'EN VIVO';
    } else if (q.estado == EstadoQuiniela.inscripcion) {
      color = ProganaColors.emerald;
      label = 'PRÓXIMA';
    } else if (q.esPendiente) {
      color = ProganaColors.grey;
      final dia = q.fechaPrimerPartido.day;
      final mes = _mesAbreviado(q.fechaPrimerPartido.month);
      label = '$dia $mes';
    } else {
      color = ProganaColors.grey;
      label = q.estado.etiqueta.toUpperCase();
    }

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

  String _mesAbreviado(int mes) {
    const meses = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return meses[mes];
  }

  // ===========================================================================
  // BOTTOM NAV (4 tabs)
  // ===========================================================================

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border(
          top: BorderSide(
            color: ProganaColors.gold.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, 'HOME'),
              _buildNavItem(1, Icons.grid_view_outlined, 'QUINIELAS'),
              _buildNavItem(2, Icons.leaderboard_outlined, 'RANKING'),
              _buildNavItem(3, Icons.person_outline, 'PERFIL'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentNavIndex == index;
    final color = isActive ? ProganaColors.gold : ProganaColors.grey;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}