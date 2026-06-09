// =============================================================================
// PROGANA Fantasy — Login Screen (Midnight Stadium)
// =============================================================================
//
// UBICACIÓN: lib/features/auth/screens/login_screen.dart
//
// REFACTOR L41-COMPLIANT:
//   ✓ Sin dart:io (compatible Flutter Web)
//   ✓ Sin OAuth, sin Forgot Password
//   ✓ Sin Back button (llegamos con pushReplacement)
//   ✓ AppConstants.minPasswordLength preservado
//   ✓ Supabase signUp + signInWithPassword INTACTO
//   ✓ Toggle login/signup preservado (_isSignupMode)
//   ✓ AuthException handling preservado
//   ✓ Navigator.pushReplacement → HomeScreen
//   ✓ .withValues(alpha:) [no deprecated .withOpacity()]
//   ✓ GoogleFonts inline (sin dependencia ProganaTextStyles)
//
// REFACTOR VISUAL — MIDNIGHT STADIUM:
//   ✓ Fondo: midnight + gradiente radial dorado
//   ✓ Logo "PROGANA" cream + "FANTASY" ShaderMask dorado
//   ✓ Card: midnight2 con borde dorado sutil
//   ✓ Inputs: midnight con borde gold al focus
//   ✓ Botón: gold con shadow dorado
//   ✓ Animación entrada: fade + slide-up 800ms
//   ✓ Tap fuera del input cierra teclado
//
// FIX DÍA 10 PM 8 JUN 2026 (Pre-Mundial):
//   ✓ _navegarAHome → _navegarPostAuth (verifica onboarding flag)
//   ✓ Nuevos signups verán OnboardingScreen (4 slides) antes de HomeScreen
//   ✓ Login con cuenta ya completed pasa directo a HomeScreen
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../home/screens/home_screen.dart';
import '../../onboarding/repository/onboarding_repository.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // CONTROLLERS Y ESTADO (preservados de tu versión original)
  // ===========================================================================

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignupMode = false;
  bool _obscurePassword = true;

  final _supabase = Supabase.instance.client;

  // L41 Día 10 PM: Onboarding flow check
  final _onboardingRepo = OnboardingRepository();

  // === ANIMACIONES (nuevo) ===
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA SUPABASE (100% IDÉNTICA A TU VERSIÓN ORIGINAL)
  // ===========================================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignupMode) {
        // SIGNUP
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.user != null && mounted) {
          _showMessage(AppConstants.exitoSignup, isError: false);
          if (response.session != null) {
            await _navegarPostAuth();
          }
        }
      } else {
        // LOGIN
        final response = await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.user != null && mounted) {
          await _navegarPostAuth();
        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage(AppConstants.errorGenerico, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// FIX DÍA 10 PM (8 jun 2026): Verifica si user debe ver onboarding
  /// antes de ir a HomeScreen.
  /// 
  /// - Nuevo signup → onboarding_completed=false → OnboardingScreen
  /// - User existente (Jorge) → onboarding_completed=true → HomeScreen
  /// - Error BD (fail-safe) → HomeScreen (no bloquear)
  Future<void> _navegarPostAuth() async {
    if (!mounted) return;

    // L41 fail-safe: si falla check, default HomeScreen
    final debeVerOnboarding = await _onboardingRepo.debeVerOnboarding();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => debeVerOnboarding
            ? const OnboardingScreen()
            : const HomeScreen(),
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
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
        backgroundColor:
            isError ? ProganaColors.crimson : ProganaColors.emerald,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0x1FD4AF37), // gold @ 12% opacity
              ProganaColors.midnight,
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            _buildLogo(),
                            const SizedBox(height: 40),
                            _buildLoginCard(),
                            const SizedBox(height: 32),
                            _buildFooter(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOGO PROGANA FANTASY
  // ===========================================================================

  Widget _buildLogo() {
    return Column(
      children: [
        // "BIENVENIDO" label
        Text(
          'BIENVENIDO',
          style: GoogleFonts.jetBrainsMono(
            color: ProganaColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),

        // "PROGANA" (cream con sombra dorada)
        Text(
          'PROGANA',
          style: GoogleFonts.archivoBlack(
            color: ProganaColors.cream,
            fontSize: 42,
            height: 0.9,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: ProganaColors.gold.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
        ),

        // "FANTASY" (gradient dorado con ShaderMask)
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
            style: GoogleFonts.archivoBlack(
              color: Colors.white, // el shader se aplica encima
              fontSize: 42,
              height: 0.9,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CARD CENTRAL (login/signup form)
  // ===========================================================================

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ProganaColors.gold.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título dinámico
          Text(
            _isSignupMode ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
            textAlign: TextAlign.center,
            style: GoogleFonts.archivoBlack(
              color: ProganaColors.cream,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _buildEmailField(),
          const SizedBox(height: 16),

          // Password
          _buildPasswordField(),
          const SizedBox(height: 24),

          // Botón principal (ENTRAR / CREAR CUENTA)
          _buildSubmitButton(),
          const SizedBox(height: 12),

          // Toggle entre login y signup
          _buildToggleButton(),
        ],
      ),
    );
  }

  // ===========================================================================
  // INPUT: EMAIL
  // ===========================================================================

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enabled: !_isLoading,
      style: GoogleFonts.outfit(
        color: ProganaColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        label: 'Correo electrónico',
        icon: Icons.mail_outline,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu correo';
        }
        if (!value.contains('@')) {
          return 'Correo inválido';
        }
        return null;
      },
    );
  }

  // ===========================================================================
  // INPUT: PASSWORD
  // ===========================================================================

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      enabled: !_isLoading,
      style: GoogleFonts.outfit(
        color: ProganaColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      onFieldSubmitted: (_) => _submit(),
      decoration: _inputDecoration(
        label: 'Contraseña',
        icon: Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: ProganaColors.creamDim,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu contraseña';
        }
        if (value.length < AppConstants.minPasswordLength) {
          return 'Mínimo ${AppConstants.minPasswordLength} caracteres';
        }
        return null;
      },
    );
  }

  // ===========================================================================
  // DECORACIÓN COMÚN PARA INPUTS
  // ===========================================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: ProganaColors.creamDim,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: ProganaColors.creamDim,
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: ProganaColors.midnight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: ProganaColors.gold,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ProganaColors.crimson),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: ProganaColors.crimson,
          width: 1.5,
        ),
      ),
      errorStyle: GoogleFonts.outfit(
        color: ProganaColors.crimson,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ===========================================================================
  // BOTÓN SUBMIT (ENTRAR / CREAR CUENTA)
  // ===========================================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProganaColors.gold,
          foregroundColor: ProganaColors.midnight,
          disabledBackgroundColor: ProganaColors.gold.withValues(alpha: 0.5),
          elevation: _isLoading ? 0 : 12,
          shadowColor: ProganaColors.gold.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: ProganaColors.midnight,
                  strokeWidth: 3,
                ),
              )
            : Text(
                _isSignupMode ? 'CREAR CUENTA' : 'ENTRAR',
                style: GoogleFonts.archivoBlack(
                  color: ProganaColors.midnight,
                  fontSize: 13,
                  letterSpacing: 1.3,
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // TOGGLE BUTTON (login ↔ signup)
  // ===========================================================================

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => setState(() => _isSignupMode = !_isSignupMode),
      child: Text(
        _isSignupMode
            ? '¿Ya tienes cuenta? Inicia sesión'
            : '¿No tienes cuenta? Regístrate',
        style: GoogleFonts.outfit(
          color: ProganaColors.gold,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================

  Widget _buildFooter() {
    return Text(
      '🇲🇽 CONCURSO DE HABILIDAD · SIN APUESTAS',
      style: GoogleFonts.jetBrainsMono(
        color: ProganaColors.creamDim,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );
  }
}