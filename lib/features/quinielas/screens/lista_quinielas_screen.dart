import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/quiniela.dart';
import '../repository/quiniela_repository.dart';

/// Pantalla principal de lista de quinielas
/// 
/// L41: Diseño premium con jerarquía visual clara
class ListaQuinielasScreen extends StatefulWidget {
  const ListaQuinielasScreen({super.key});

  @override
  State<ListaQuinielasScreen> createState() => _ListaQuinielasScreenState();
}

class _ListaQuinielasScreenState extends State<ListaQuinielasScreen> {
  final _repository = QuinielaRepository();
  late Future<List<Quiniela>> _futureQuinielas;

  @override
  void initState() {
    super.initState();
    _cargarQuinielas();
  }

  void _cargarQuinielas() {
    setState(() {
      _futureQuinielas = _repository.obtenerTodasQuinielas();
    });
  }

  Future<void> _refrescar() async {
    _cargarQuinielas();
    await _futureQuinielas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Quinielas Mundial 2026',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarQuinielas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        color: AppColors.verdeMexicano,
        child: FutureBuilder<List<Quiniela>>(
          future: _futureQuinielas,
          builder: (context, snapshot) {
            // ESTADO 1: Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.verdeMexicano),
                    SizedBox(height: 16),
                    Text(
                      'Cargando quinielas...',
                      style: TextStyle(color: AppColors.grisMedio),
                    ),
                  ],
                ),
              );
            }

            // ESTADO 2: Error
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No pudimos cargar las quinielas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.grisMedio,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _cargarQuinielas,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // ESTADO 3: Vacío
            final quinielas = snapshot.data ?? [];
            if (quinielas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            size: 64,
                            color: AppColors.grisMedio,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay quinielas disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pronto habrá nuevas quinielas\npara el Mundial 2026',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grisMedio),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // ESTADO 4: Con datos
            return Column(
              children: [
                // Header con contador
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.verdeMexicano.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.verdeMexicano,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${quinielas.length} ${quinielas.length == 1 ? "Quiniela" : "Quinielas"}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grisOscuro,
                              ),
                            ),
                            const Text(
                              'Mundial FIFA 2026',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grisMedio,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '🇲🇽 🇺🇸 🇨🇦',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // Separador sutil
                Container(
                  height: 1,
                  color: const Color(0xFFE8EBEF),
                ),
                // Lista de cards
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: quinielas.length,
                    itemBuilder: (context, index) {
                      return _QuinielaCard(quiniela: quinielas[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Card visual PREMIUM de una quiniela
class _QuinielaCard extends StatelessWidget {
  final Quiniela quiniela;

  const _QuinielaCard({required this.quiniela});

  /// Parsea el color hex de la BD (ej: "#0066CC") a Color
  Color _parseColor() {
    if (quiniela.colorPrimario == null) return AppColors.verdeMexicano;
    try {
      final hex = quiniela.colorPrimario!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.verdeMexicano;
    }
  }

  /// Color según el estado de la quiniela
  Color _colorEstado() {
    switch (quiniela.estado) {
      case EstadoQuiniela.inscripcion:
        return AppColors.exito;
      case EstadoQuiniela.activa:
        return AppColors.info;
      case EstadoQuiniela.borrador:
        return AppColors.dorado;
      case EstadoQuiniela.finalizada:
        return AppColors.grisMedio;
      case EstadoQuiniela.cancelada:
        return AppColors.error;
    }
  }

  /// Icono según el estado
  IconData _iconoEstado() {
    switch (quiniela.estado) {
      case EstadoQuiniela.inscripcion:
        return Icons.check_circle_rounded;
      case EstadoQuiniela.activa:
        return Icons.play_circle_filled_rounded;
      case EstadoQuiniela.borrador:
        return Icons.schedule_rounded;
      case EstadoQuiniela.finalizada:
        return Icons.emoji_events_rounded;
      case EstadoQuiniela.cancelada:
        return Icons.cancel_rounded;
    }
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colorBanner = _parseColor();
    final colorEstado = _colorEstado();
    final iconoEstado = _iconoEstado();
    final numeroQ = quiniela.numeroOrden.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorBanner.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detalle de "${quiniela.nombre}" - Próximamente'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════
              // HEADER PREMIUM con número Q gigante
              // ═══════════════════════════════════════════════════════
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorBanner,
                        colorBanner.withValues(alpha: 0.85),
                        Color.lerp(colorBanner, Colors.black, 0.2)!,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Patrón decorativo - círculos sutiles
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        top: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      // Icono balón de fondo (decorativo)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Icon(
                          Icons.sports_soccer_rounded,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      // Contenido principal
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Número Q gigante
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  numeroQ,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 32,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Info principal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'JORNADA',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quiniela.nombre.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  // Badge de estado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          iconoEstado,
                                          size: 12,
                                          color: colorEstado,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          quiniela.estado.etiqueta.toUpperCase(),
                                          style: TextStyle(
                                            color: colorEstado,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════
              // BODY - Fecha + Métricas
              // ═══════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de fecha con cuenta regresiva
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorBanner.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: colorBanner,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INICIA',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.grisMedio,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              _formatearFecha(quiniela.fechaPrimerPartido),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grisOscuro,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (quiniela.diasParaInicio != null &&
                            quiniela.diasParaInicio! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.dorado,
                                  AppColors.dorado.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dorado.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_rounded,
                                  size: 14,
                                  color: AppColors.grisOscuro,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${quiniela.diasParaInicio} días',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.grisOscuro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Descripción si existe
                    if (quiniela.descripcion != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: const Color(0xFFEEF1F4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        quiniela.descripcion!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grisMedio,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFFEEF1F4),
                    ),
                    const SizedBox(height: 16),

                    // Métricas como mini-cards
                    Row(
                      children: [
                        Expanded(
                          child: _MetricaMiniCard(
                            icon: Icons.people_alt_rounded,
                            valor: '${quiniela.totalInscritos}',
                            etiqueta: 'INSCRITOS',
                            color: colorBanner,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricaMiniCard(
                            icon: Icons.fact_check_rounded,
                            valor: '${quiniela.totalPredicciones}',
                            etiqueta: 'PREDICCIONES',
                            color: colorBanner,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorBanner,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
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
      ),
    );
  }
}

/// Mini card para métrica individual
class _MetricaMiniCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String etiqueta;
  final Color color;

  const _MetricaMiniCard({
    required this.icon,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEEF1F4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.grisMedio,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}