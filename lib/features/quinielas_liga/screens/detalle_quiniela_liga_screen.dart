import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/partido_liga.dart';
import '../models/participacion_liga.dart';
import '../models/quiniela_liga.dart';
import '../repository/quiniela_liga_repository.dart';
import 'quiniela_qr_screen.dart';
import 'panel_liga_screen.dart';

/// Detalle de una quiniela de clubes: datos + activación + participantes + partidos + QR.
class DetalleQuinielaLigaScreen extends StatefulWidget {
  final QuinielaLiga quiniela;
  const DetalleQuinielaLigaScreen({super.key, required this.quiniela});

  @override
  State<DetalleQuinielaLigaScreen> createState() =>
      _DetalleQuinielaLigaScreenState();
}

class _DetalleQuinielaLigaScreenState extends State<DetalleQuinielaLigaScreen> {
  final _repo = QuinielaLigaRepository();
  bool _cargando = true;
  bool _activando = false;
  String? _error;
  List<PartidoLiga> _partidos = [];

  // Participantes (lado promotor)
  List<ParticipacionLiga> _participaciones = [];
  bool _cargandoParts = true;
  int? _accionId; // id de la participación en proceso (confirmar/rechazar)

  /// Copia local mutable: se actualiza al activar (borrador→inscripción).
  late QuinielaLiga _q;

  @override
  void initState() {
    super.initState();
    _q = widget.quiniela;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ps = await _repo.getPartidosDeQuiniela(_q.id);
      if (!mounted) return;
      setState(() {
        _partidos = ps;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
    _cargarParticipaciones();
  }

  Future<void> _cargarParticipaciones() async {
    setState(() => _cargandoParts = true);
    try {
      final parts = await _repo.getParticipaciones(_q.id);
      if (!mounted) return;
      setState(() {
        _participaciones = parts;
        _cargandoParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoParts = false);
    }
  }

  Future<void> _activar() async {
    setState(() => _activando = true);
    try {
      // Modo prueba: gratis=true. Cuando haya OpenPay real → gratis=false.
      final actualizada = await _repo.activarQuiniela(_q.id, gratis: true);
      if (!mounted) return;
      setState(() {
        _q = actualizada;
        _activando = false;
      });
      _snack(_q.estado == 'inscripcion'
          ? '¡Activada! Ya está en inscripción.'
          : 'Activada (estado: ${_q.estado}).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _activando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmar(ParticipacionLiga p) async {
    setState(() => _accionId = p.id);
    try {
      await _repo.confirmarParticipacion(p.id);
      if (!mounted) return;
      _snack('${p.nombre} confirmado. Ya puede predecir.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _accionId = null);
      await _cargarParticipaciones();
    }
  }

  Future<void> _rechazar(ParticipacionLiga p) async {
    setState(() => _accionId = p.id);
    try {
      await _repo.rechazarParticipacion(p.id);
      if (!mounted) return;
      _snack('${p.nombre} rechazado.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _accionId = null);
      await _cargarParticipaciones();
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _verQr() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuinielaQrScreen(quiniela: _q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esBorrador = _q.estado == 'borrador';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            tooltip: 'Panel',
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  PanelLigaScreen(quinielaId: _q.id, nombre: _q.nombre),
            )),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ProganaSpacing.lg),
          children: [
            _header(),
            if (esBorrador) ...[
              const SizedBox(height: ProganaSpacing.lg),
              _tarjetaActivar(),
            ],
            const SizedBox(height: ProganaSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verQr,
                icon: const Icon(Icons.qr_code_2, size: 20),
                label: const Text('VER / COMPARTIR QR'),
              ),
            ),

            // ---- PARTICIPANTES ----
            const SizedBox(height: ProganaSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PARTICIPANTES', style: ProganaTextStyles.labelLarge),
                Text('${_participaciones.length}',
                    style: ProganaTextStyles.scoreMedium),
              ],
            ),
            const SizedBox(height: ProganaSpacing.sm),
            _listaParticipantes(),

            // ---- PARTIDOS ----
            const SizedBox(height: ProganaSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PARTIDOS', style: ProganaTextStyles.labelLarge),
                Text('${_partidos.length}',
                    style: ProganaTextStyles.scoreMedium),
              ],
            ),
            const SizedBox(height: ProganaSpacing.sm),
            _listaPartidos(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: ProganaSpacing.cardPaddingLarge,
      decoration: ProganaDecorations.cardGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child:
                      Text(_q.nombre, style: ProganaTextStyles.displaySmall)),
              const SizedBox(width: ProganaSpacing.xs),
              _pillEstado(_q.estado),
            ],
          ),
          const SizedBox(height: ProganaSpacing.sm),
          Row(
            children: [
              const Icon(Icons.qr_code,
                  size: 14, color: ProganaColors.creamDim),
              const SizedBox(width: 6),
              Text(_q.codigoInvitacion,
                  style: ProganaTextStyles.labelMedium
                      .copyWith(color: ProganaColors.emerald)),
              const Spacer(),
              const Icon(Icons.group,
                  size: 14, color: ProganaColors.creamDim),
              const SizedBox(width: 6),
              Text('${_q.totalInscritos}/${_q.capacidadMaxima ?? '-'}',
                  style: ProganaTextStyles.labelMedium),
            ],
          ),
        ],
      ),
    );
  }

  /// CTA visible solo en borrador: activar para abrir inscripciones.
  Widget _tarjetaActivar() {
    return Container(
      padding: ProganaSpacing.cardPaddingLarge,
      decoration: ProganaDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: ProganaColors.gold),
              const SizedBox(width: 8),
              Text('EN BORRADOR', style: ProganaTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: ProganaSpacing.xs),
          Text(
            'Actívala para abrir inscripciones y que puedan unirse participantes.',
            style: ProganaTextStyles.bodySmall,
          ),
          const SizedBox(height: ProganaSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _activando ? null : _activar,
              icon: _activando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch, size: 20),
              label: Text(
                  _activando ? 'ACTIVANDO...' : 'ACTIVAR (modo prueba)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillEstado(String estado) {
    Color c;
    switch (estado) {
      case 'activa':
        c = ProganaColors.emerald;
        break;
      case 'inscripcion':
        c = ProganaColors.gold;
        break;
      case 'finalizada':
        c = ProganaColors.grey;
        break;
      case 'cancelada':
        c = ProganaColors.crimson;
        break;
      default:
        c = ProganaColors.creamDim;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(estado.toUpperCase(),
          style: ProganaTextStyles.labelSmall.copyWith(color: c)),
    );
  }

  // ---------------------------------------------------------------------------
  // PARTICIPANTES
  // ---------------------------------------------------------------------------

  Widget _listaParticipantes() {
    if (_cargandoParts) {
      return const Padding(
        padding: EdgeInsets.all(ProganaSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_participaciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        child: Center(
          child: Text('Aún nadie se ha unido',
              style: ProganaTextStyles.bodySmall),
        ),
      );
    }
    return Column(
      children: _participaciones.map(_filaParticipante).toList(),
    );
  }

  Widget _filaParticipante(ParticipacionLiga p) {
    final enProceso = _accionId == p.id;
    final hayAccion = _accionId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: ProganaSpacing.xs),
      padding: ProganaSpacing.cardPadding,
      decoration: ProganaDecorations.card,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: ProganaTextStyles.bodyLarge),
                if (p.email != null && p.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(p.email!,
                      style: ProganaTextStyles.labelMedium
                          .copyWith(color: ProganaColors.creamDim)),
                ],
                const SizedBox(height: 4),
                _pillParticipante(p.estado),
              ],
            ),
          ),
          if (p.pendiente) ...[
            if (enProceso)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                onPressed: hayAccion ? null : () => _confirmar(p),
                icon: const Icon(Icons.check_circle,
                    color: ProganaColors.emerald),
                tooltip: 'Confirmar',
              ),
              IconButton(
                onPressed: hayAccion ? null : () => _rechazar(p),
                icon: const Icon(Icons.cancel, color: ProganaColors.crimson),
                tooltip: 'Rechazar',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _pillParticipante(String estado) {
    late Color c;
    late String label;
    switch (estado) {
      case 'activo':
        c = ProganaColors.emerald;
        label = 'ACTIVO';
        break;
      case 'confirmado_plus':
        c = ProganaColors.gold;
        label = 'POR CONFIRMAR';
        break;
      case 'invitado':
        c = ProganaColors.creamDim;
        label = 'INVITADO';
        break;
      case 'rechazado':
        c = ProganaColors.crimson;
        label = 'RECHAZADO';
        break;
      default:
        c = ProganaColors.grey;
        label = estado.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: ProganaTextStyles.labelSmall.copyWith(color: c)),
    );
  }

  // ---------------------------------------------------------------------------
  // PARTIDOS
  // ---------------------------------------------------------------------------

  Widget _listaPartidos() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(ProganaSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!,
              textAlign: TextAlign.center,
              style: ProganaTextStyles.bodyMedium),
          const SizedBox(height: ProganaSpacing.sm),
          ElevatedButton(onPressed: _cargar, child: const Text('REINTENTAR')),
        ],
      );
    }
    if (_partidos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProganaSpacing.xl),
        child: Center(
            child: Text('Sin partidos', style: ProganaTextStyles.bodySmall)),
      );
    }
    return Column(
      children: _partidos.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: ProganaSpacing.xs),
          padding: ProganaSpacing.cardPadding,
          decoration: ProganaDecorations.card,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProganaColors.goldOverlay(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${i + 1}', style: ProganaTextStyles.labelSmall),
              ),
              const SizedBox(width: ProganaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _miniChip(p.competicionCorto),
                        const SizedBox(width: 6),
                        Text('J${p.jornada ?? '-'} · ${_fmtFecha(p.fechaHora)}',
                            style: ProganaTextStyles.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _teamsRow(p),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _miniChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: ProganaColors.goldOverlay(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: ProganaTextStyles.labelSmall),
      );

  Widget _teamsRow(PartidoLiga p) {
    return Row(
      children: [
        _escudo(p.localEscudo, p.localNombre),
        const SizedBox(width: 6),
        Expanded(
          child: Text(p.localNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ProganaTextStyles.bodyLarge),
        ),
        Text(' vs ',
            style: ProganaTextStyles.labelMedium
                .copyWith(color: ProganaColors.creamDim)),
        Expanded(
          child: Text(p.visitanteNombre,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ProganaTextStyles.bodyLarge),
        ),
        const SizedBox(width: 6),
        _escudo(p.visitanteEscudo, p.visitanteNombre),
      ],
    );
  }

  Widget _escudo(String? url, String nombre) {
    const double s = 24;
    if (url == null || url.isEmpty) return _escudoFallback(nombre, s);
    return ClipOval(
      child: Image.network(
        url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _escudoFallback(nombre, s),
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : _escudoFallback(nombre, s),
      ),
    );
  }

  Widget _escudoFallback(String nombre, double s) {
    final t = nombre.trim();
    final ini = t.isEmpty
        ? '?'
        : (t.length >= 2 ? t.substring(0, 2) : t.substring(0, 1)).toUpperCase();
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ProganaColors.midnight3,
        border:
            Border.all(color: ProganaColors.creamDim.withValues(alpha: 0.3)),
      ),
      child: Text(ini,
          style: ProganaTextStyles.labelSmall
              .copyWith(color: ProganaColors.creamDim)),
    );
  }

  String _fmtFecha(DateTime utc) {
    final d = utc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
