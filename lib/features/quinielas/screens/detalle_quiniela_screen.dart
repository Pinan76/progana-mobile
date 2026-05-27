import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/quiniela.dart';
import '../models/partido.dart';
import '../repository/partido_repository.dart';

/// Pantalla de Detalle de una Quiniela
/// 
/// L41: Diseño premium con jerarquía visual
/// Recibe el objeto Quiniela completo (ya cargado desde la lista)
class DetalleQuinielaScreen extends StatefulWidget {
  final Quiniela quiniela;

  const DetalleQuinielaScreen({super.key, required this.quiniela});

  @override
  State<DetalleQuinielaScreen> createState() => _DetalleQuinielaScreenState();
}

class _DetalleQuinielaScreenState extends State<DetalleQuinielaScreen> {
  final _partidoRepo = PartidoRepository();
  late Future<List<Partido>> _futurePartidos;

  @override
  void initState() {
    super.initState();
    _cargarPartidos();
  }

  void _cargarPartidos() {
    setState(() {
      _futurePartidos = _partidoRepo.obtenerPartidosDeQuiniela(widget.quiniela.id);
    });
  }

  Color get _colorBanner {
    if (widget.quiniela.colorPrimario == null) return AppColors.verdeMexicano;
    try {
      final hex = widget.quiniela.colorPrimario!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.verdeMexicano;
    }
  }

  Color get _colorEstado {
    switch (widget.quiniela.estado) {
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

  IconData get _iconoEstado {
    switch (widget.quiniela.estado) {
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

  String _formatearFechaCompleta(DateTime fecha) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]}';
  }

  String _formatearFechaCorta(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  String _formatearHora(DateTime fecha) {
    final local = fecha.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorBanner;
    final numeroQ = widget.quiniela.numeroOrden.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // ═════════════════════════════════════════════════════════
          // SLIVER APPBAR PREMIUM con header expandible
          // ═════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Q$numeroQ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.85),
                      Color.lerp(color, Colors.black, 0.3)!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Círculos decorativos
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: 70,
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    // Contenido (FIX L41: padding reducido + número Q más pequeño)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                numeroQ,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'JORNADA',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.quiniela.nombre.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Badge estado
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                                  _iconoEstado,
                                  size: 14,
                                  color: _colorEstado,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.quiniela.estado.etiqueta.toUpperCase(),
                                  style: TextStyle(
                                    color: _colorEstado,
                                    fontSize: 11,
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
            ),
          ),

          // ═════════════════════════════════════════════════════════
          // BODY - SLIVER LIST con secciones
          // ═════════════════════════════════════════════════════════
          SliverList(
            delegate: SliverChildListDelegate([
              // Sección: Descripción
              if (widget.quiniela.descripcion != null)
                _SeccionDescripcion(
                  descripcion: widget.quiniela.descripcion!,
                ),

              // Sección: Información clave
              _SeccionInformacion(
                quiniela: widget.quiniela,
                colorBanner: color,
                formatearFecha: _formatearFechaCompleta,
              ),

              // Sección: Partidos
              _SeccionPartidos(
                futurePartidos: _futurePartidos,
                colorBanner: color,
                formatearFecha: _formatearFechaCorta,
                formatearHora: _formatearHora,
                onReintentar: _cargarPartidos,
              ),

              // CTA inferior
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Inscripción - Próximamente'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'INSCRIBIRME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SECCIÓN: Descripción
// ═══════════════════════════════════════════════════════════════════
class _SeccionDescripcion extends StatelessWidget {
  final String descripcion;

  const _SeccionDescripcion({required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.grisMedio,
              ),
              const SizedBox(width: 8),
              const Text(
                'ACERCA DE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grisMedio,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grisOscuro,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SECCIÓN: Información clave
// ═══════════════════════════════════════════════════════════════════
class _SeccionInformacion extends StatelessWidget {
  final Quiniela quiniela;
  final Color colorBanner;
  final String Function(DateTime) formatearFecha;

  const _SeccionInformacion({
    required this.quiniela,
    required this.colorBanner,
    required this.formatearFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 18,
                color: AppColors.grisMedio,
              ),
              const SizedBox(width: 8),
              const Text(
                'INFORMACIÓN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grisMedio,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.login_rounded,
            etiqueta: 'Inscripciones',
            valor: formatearFecha(quiniela.aperturaInscripcion),
            color: colorBanner,
          ),
          if (quiniela.cierreInscripcion != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.lock_clock_rounded,
              etiqueta: 'Cierre',
              valor: formatearFecha(quiniela.cierreInscripcion!),
              color: colorBanner,
            ),
          ],
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.flag_rounded,
            etiqueta: 'Primer partido',
            valor: formatearFecha(quiniela.fechaPrimerPartido),
            color: colorBanner,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.emoji_events_rounded,
            etiqueta: 'Último partido',
            valor: formatearFecha(quiniela.fechaUltimoPartido),
            color: colorBanner,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEEF1F4)),
          const SizedBox(height: 16),
          // Métricas
          Row(
            children: [
              Expanded(
                child: _MetricaItem(
                  icon: Icons.people_alt_rounded,
                  valor: '${quiniela.totalInscritos}',
                  etiqueta: 'INSCRITOS',
                  color: colorBanner,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricaItem(
                  icon: Icons.fact_check_rounded,
                  valor: '${quiniela.totalPredicciones}',
                  etiqueta: 'PREDICCIONES',
                  color: colorBanner,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String etiqueta;
  final String valor;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grisMedio,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grisOscuro,
          ),
        ),
      ],
    );
  }
}

class _MetricaItem extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String etiqueta;
  final Color color;

  const _MetricaItem({
    required this.icon,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
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
                  fontSize: 20,
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

// ═══════════════════════════════════════════════════════════════════
// SECCIÓN: Lista de partidos
// ═══════════════════════════════════════════════════════════════════
class _SeccionPartidos extends StatelessWidget {
  final Future<List<Partido>> futurePartidos;
  final Color colorBanner;
  final String Function(DateTime) formatearFecha;
  final String Function(DateTime) formatearHora;
  final VoidCallback onReintentar;

  const _SeccionPartidos({
    required this.futurePartidos,
    required this.colorBanner,
    required this.formatearFecha,
    required this.formatearHora,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Partido>>(
      future: futurePartidos,
      builder: (context, snapshot) {
        // Header de la sección (siempre visible)
        Widget header(int? cantidad) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_soccer_rounded,
                    size: 18,
                    color: AppColors.grisMedio,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PARTIDOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grisMedio,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (cantidad != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorBanner.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cantidad ${cantidad == 1 ? "partido" : "partidos"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorBanner,
                        ),
                      ),
                    ),
                ],
              ),
            );

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              header(null),
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.verdeMexicano,
                  ),
                ),
              ),
            ],
          );
        }

        // Error
        if (snapshot.hasError) {
          return Column(
            children: [
              header(null),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grisMedio,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onReintentar,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final partidos = snapshot.data ?? [];

        // Vacío
        if (partidos.isEmpty) {
          return Column(
            children: [
              header(0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 48,
                      color: AppColors.grisMedio,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Partidos por definir',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grisMedio,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Lista de partidos
        return Column(
          children: [
            header(partidos.length),
            ...partidos.map((p) => _PartidoCard(
                  partido: p,
                  colorBanner: colorBanner,
                  formatearFecha: formatearFecha,
                  formatearHora: formatearHora,
                )),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Card individual de partido
// ═══════════════════════════════════════════════════════════════════
class _PartidoCard extends StatelessWidget {
  final Partido partido;
  final Color colorBanner;
  final String Function(DateTime) formatearFecha;
  final String Function(DateTime) formatearHora;

  const _PartidoCard({
    required this.partido,
    required this.colorBanner,
    required this.formatearFecha,
    required this.formatearHora,
  });

  @override
  Widget build(BuildContext context) {
    final local = partido.equipoLocal;
    final visit = partido.equipoVisit;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F4), width: 1),
      ),
      child: Column(
        children: [
          // Header: número partido + fecha + hora
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colorBanner.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${partido.numeroPartido}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorBanner,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatearFecha(partido.fechaHora),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grisOscuro,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.grisMedio,
              ),
              const SizedBox(width: 4),
              Text(
                formatearHora(partido.fechaHora),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grisMedio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Equipos vs
          Row(
            children: [
              // Local
              Expanded(
                child: _EquipoLado(
                  emoji: local?.emojiBandera ?? '⚽',
                  codigo: local?.codigo ?? 'TBD',
                  nombre: local?.nombre ?? 'Por definir',
                  alineacion: CrossAxisAlignment.center,
                ),
              ),
              // Marcador / VS
              SizedBox(
                width: 70,
                child: Column(
                  children: [
                    if (partido.estado.yaFinalizo &&
                        partido.golesLocal != null)
                      Text(
                        partido.marcador,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.grisOscuro,
                        ),
                      )
                    else
                      const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grisMedio,
                          letterSpacing: 2,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (partido.estado.yaFinalizo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grisMedio.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FINAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grisMedio,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    else if (partido.estado == EstadoPartido.enJuego)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EN VIVO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Visit
              Expanded(
                child: _EquipoLado(
                  emoji: visit?.emojiBandera ?? '⚽',
                  codigo: visit?.codigo ?? 'TBD',
                  nombre: visit?.nombre ?? 'Por definir',
                  alineacion: CrossAxisAlignment.center,
                ),
              ),
            ],
          ),
          // Ubicación (si existe)
          if (partido.ciudad != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFEEF1F4)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: AppColors.grisMedio,
                ),
                const SizedBox(width: 4),
                Text(
                  partido.ciudad!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grisMedio,
                  ),
                ),
                if (partido.estadio != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· ${partido.estadio}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grisMedio,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EquipoLado extends StatelessWidget {
  final String emoji;
  final String codigo;
  final String nombre;
  final CrossAxisAlignment alineacion;

  const _EquipoLado({
    required this.emoji,
    required this.codigo,
    required this.nombre,
    required this.alineacion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alineacion,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text(
          codigo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.grisOscuro,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          nombre,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.grisMedio,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}