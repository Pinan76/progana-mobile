import 'package:flutter/material.dart';
import '../../core/theme/progana_theme.dart';
import '../../core/constants/app_constants.dart';
import '../auth/screens/login_screen.dart';

/// Splash Screen — PROGANA Fantasy
///
/// L41: Refactorizado a tema "Midnight Stadium" 29 may 2026
/// Mantiene auto-redirect a LoginScreen (comportamiento original)
/// Cambia estética: midnight + gold + Archivo Black + trofeo SVG custom
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _trophyController;
  late Animation<double> _logoFade;
  late Animation<double> _trophyScale;

  @override
  void initState() {
    super.initState();

    // Animación 1: Logo (fade-in)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Animación 2: Trofeo (scale + fade)
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _trophyScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyController,
        curve: Curves.easeOutBack,
      ),
    );

    // Secuencia: logo → trofeo
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _trophyController.forward();
    });

    // Auto-navigate al Login después del Splash (comportamiento original)
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              Color(0x26D4AF37), // gold @ 15% opacity
              ProganaColors.midnight,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Capa decorativa: grid sutil (atmósfera estadio)
            Positioned.fill(
              child: CustomPaint(painter: _GridBackgroundPainter()),
            ),

            // Contenido principal
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ===== LOGO =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: _buildLogo(),
                    ),

                    const SizedBox(height: 16),

                    // ===== TAGLINE DECORATIVA =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: _buildTagline(),
                    ),

                    const Spacer(flex: 1),

                    // ===== TROFEO =====
                    ScaleTransition(
                      scale: _trophyScale,
                      child: FadeTransition(
                        opacity: _trophyController,
                        child: SizedBox(
                          width: 200,
                          height: 130,
                          child: CustomPaint(painter: _TrophyPainter()),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== BANDERAS HOST =====
                    FadeTransition(
                      opacity: _trophyController,
                      child: const Text(
                        '🇲🇽 🇺🇸 🇨🇦',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ===== LOADING =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ProganaColors.gold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'CARGANDO',
                      style: ProganaTextStyles.labelMedium.copyWith(
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ===== FOOTER (operadora legal) =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: Text(
                        AppConstants.appOperadora,
                        style: ProganaTextStyles.labelMedium.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: ProganaColors.creamDim.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
  // WIDGETS PRIVADOS
  // ===========================================================================

  Widget _buildLogo() {
    return Column(
      children: [
        // "PROGANA" en crema con sombra dorada
        Text(
          'PROGANA',
          style: ProganaTextStyles.displayLarge.copyWith(
            fontSize: 52,
            height: 0.9,
            shadows: [
              Shadow(
                color: ProganaColors.gold.withValues(alpha: 0.3),
                blurRadius: 40,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        // "FANTASY" con gradiente dorado
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              ProganaColors.goldBright,
              ProganaColors.gold,
              ProganaColors.goldDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'FANTASY',
            style: ProganaTextStyles.displayLarge.copyWith(
              fontSize: 52,
              height: 0.9,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '──',
          style: TextStyle(
            color: ProganaColors.gold.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'MUNDIAL 2026',
          style: ProganaTextStyles.labelLarge.copyWith(fontSize: 10),
        ),
        const SizedBox(width: 12),
        Text(
          '──',
          style: TextStyle(
            color: ProganaColors.gold.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: GRID DE FONDO (atmósfera estadio)
// =============================================================================

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ProganaColors.gold.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 30.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// =============================================================================
// CUSTOM PAINTER: TROFEO DORADO
// =============================================================================

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // === FONDO: gradiente sutil del trofeo ===
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          ProganaColors.gold.withValues(alpha: 0.4),
          ProganaColors.gold.withValues(alpha: 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final strokePaint = Paint()
      ..color = ProganaColors.gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // === COPA DEL TROFEO ===
    final cupPath = Path()
      ..moveTo(w * 0.385, h * 0.23)
      ..lineTo(w * 0.385, h * 0.38)
      ..quadraticBezierTo(
        w * 0.385, h * 0.54,
        w * 0.50, h * 0.60,
      )
      ..quadraticBezierTo(
        w * 0.615, h * 0.54,
        w * 0.615, h * 0.38,
      )
      ..lineTo(w * 0.615, h * 0.23)
      ..close();

    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, strokePaint);

    // === ASA IZQUIERDA ===
    final leftHandlePath = Path()
      ..moveTo(w * 0.34, h * 0.23)
      ..quadraticBezierTo(
        w * 0.34, h * 0.35,
        w * 0.385, h * 0.38,
      );
    canvas.drawPath(leftHandlePath, strokePaint);

    // === ASA DERECHA ===
    final rightHandlePath = Path()
      ..moveTo(w * 0.66, h * 0.23)
      ..quadraticBezierTo(
        w * 0.66, h * 0.35,
        w * 0.615, h * 0.38,
      );
    canvas.drawPath(rightHandlePath, strokePaint);

    // === CUELLO (entre copa y base) ===
    final neckPaint = Paint()..color = ProganaColors.gold;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.455, h * 0.60, w * 0.09, h * 0.06),
      neckPaint,
    );

    // === BASE ===
    final basePath = Path()
      ..moveTo(w * 0.42, h * 0.66)
      ..lineTo(w * 0.58, h * 0.66)
      ..lineTo(w * 0.58, h * 0.75)
      ..lineTo(w * 0.42, h * 0.75)
      ..close();
    canvas.drawPath(basePath, fillPaint);
    canvas.drawPath(basePath, strokePaint);

    // === ESTRELLAS DECORATIVAS ===
    final starPaint = Paint()..color = ProganaColors.gold;
    final stars = [
      (w * 0.18, h * 0.15, 1.0),
      (w * 0.82, h * 0.20, 1.5),
      (w * 0.90, h * 0.40, 1.0),
      (w * 0.11, h * 0.45, 1.0),
      (w * 0.85, h * 0.75, 1.2),
    ];

    for (final star in stars) {
      canvas.drawCircle(Offset(star.$1, star.$2), star.$3, starPaint);
    }

    // === LÍNEA DE CANCHA (debajo del trofeo) ===
    final fieldPaint = Paint()
      ..color = ProganaColors.emerald
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Línea punteada
    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = w * 0.08;
    while (startX < w * 0.92) {
      canvas.drawLine(
        Offset(startX, h * 0.88),
        Offset(startX + dashWidth, h * 0.88),
        fieldPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Elipse central (medio campo)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.18,
        height: 8,
      ),
      fieldPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}