// =============================================================================
// PROGANA Fantasy — OnboardingScreen (Welcome Flow)
// =============================================================================
//
// L41 COMPLIANT (8 jun 2026 - Día 10 PM):
//   ✓ 4 slides Mundial 2026 (definidos en OnboardingSlides)
//   ✓ PageView con swipe + botón "Siguiente"
//   ✓ Botón "Saltar" grande tappable (top right)
//   ✓ Animación fade+slide entre slides
//   ✓ Dots indicator de progreso
//   ✓ Marca onboarding_completed=true al finalizar/saltar
//   ✓ Navegación final → HomeScreen (pushReplacement)
//   ✓ Compatible Flutter Web (sin dart:io)
//   ✓ .withValues(alpha:) consistente
//   ✓ Midnight Stadium design system
//
// Flujo:
// 1. User signup → handle_new_user trigger crea profile (onboarding=false)
// 2. SplashScreen verifica flag → push OnboardingScreen
// 3. User ve 4 slides + tap "EMPEZAR" o "SALTAR"
// 4. marcarCompletado() → onboarding=true en BD
// 5. pushReplacement → HomeScreen
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/progana_theme.dart';
import '../../home/screens/home_screen.dart';
import '../models/onboarding_slide.dart';
import '../repository/onboarding_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OnboardingRepository _repo = OnboardingRepository();

  int _currentPage = 0;
  bool _isFinishing = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late final List<OnboardingSlide> _slides = OnboardingSlides.all;

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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Re-trigger fade animation on each page change
    _fadeController.reset();
    _fadeController.forward();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  Future<void> _onFinish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    // L41: Marcar completado en BD (fire-forget defensive)
    await _repo.marcarCompletado();

    if (!mounted) return;

    // pushReplacement: no permitir back a onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _onSkip() async {
    // Mismo flow que finish (saltar también marca completado)
    _onFinish();
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
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildSlide(_slides[index]),
                  );
                },
              ),
            ),
            _buildDotsIndicator(),
            const SizedBox(height: 20),
            _buildBottomNav(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR — Botón SALTAR grande
  // ===========================================================================

  Widget _buildTopBar() {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo PROGANA
          Row(
            children: [
              const Text('⚽', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'PROGANA',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.cream,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // Botón SALTAR (no se muestra en último slide)
          if (!isLastSlide)
            GestureDetector(
              onTap: _onSkip,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ProganaColors.midnight2,
                  border: Border.all(
                    color: ProganaColors.creamDim.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SALTAR',
                      style: GoogleFonts.jetBrainsMono(
                        color: ProganaColors.creamDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: ProganaColors.creamDim,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE CONTENT
  // ===========================================================================

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EMOJI grande con glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.colorAccent.withValues(alpha: 0.2),
                  slide.colorAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              slide.emoji,
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 32),

          // TÍTULO (puede tener \n)
          Text(
            slide.titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 26,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          // SUBTÍTULO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.colorAccent.withValues(alpha: 0.15),
              border: Border.all(
                color: slide.colorAccent.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              slide.subtitulo,
              style: GoogleFonts.jetBrainsMono(
                color: slide.colorAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // DESCRIPCIÓN
          Text(
            slide.descripcion,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: ProganaColors.creamDim,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          // BULLETS (opcional)
          if (slide.bulletPoints != null) ...[
            const SizedBox(height: 20),
            ...slide.bulletPoints!.map((bullet) => _buildBullet(bullet, slide.colorAccent)),
          ],
        ],
      ),
    );
  }

  Widget _buildBullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ProganaColors.midnight2,
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: ProganaColors.cream,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DOTS INDICATOR
  // ===========================================================================

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? ProganaColors.gold : ProganaColors.creamDim.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // BOTTOM NAV — Siguiente / Empezar
  // ===========================================================================

  Widget _buildBottomNav() {
    final isLastSlide = _currentPage == _slides.length - 1;
    final isLoading = _isFinishing;

    final Color buttonColor = isLastSlide ? ProganaColors.emerald : ProganaColors.gold;
    final String buttonLabel = isLastSlide ? 'EMPEZAR' : 'SIGUIENTE';
    final IconData buttonIcon = isLastSlide
        ? Icons.sports_soccer_rounded
        : Icons.arrow_forward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: ProganaColors.midnight,
            disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: ProganaColors.midnight,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      style: GoogleFonts.archivoBlack(
                        color: ProganaColors.midnight,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(buttonIcon, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}