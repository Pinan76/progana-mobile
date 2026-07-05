import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/mi_quiniela_liga.dart';
import '../models/partido_liga.dart';
import '../repository/quiniela_liga_repository.dart';
import '../../predict/models/prediction_result.dart';
import '../../predict/repository/predict_repository.dart';
import 'panel_liga_screen.dart';

/// Vista de PARTICIPANTE (una participación): predice L/E/V, GUARDA y CONFIRMA.
/// Re-llaveada por participacion_id. Incluye "Nueva participación" y "Ver panel".
class ParticipanteDetalleLigaScreen extends StatefulWidget {
  final MiQuinielaLiga item;
  const ParticipanteDetalleLigaScreen({super.key, required this.item});

  @override
  State<ParticipanteDetalleLigaScreen> createState() =>
      _ParticipanteDetalleLigaScreenState();
}

class _ParticipanteDetalleLigaScreenState
    extends State<ParticipanteDetalleLigaScreen> {
  final _repo = QuinielaLigaRepository();
  final _predictRepo = PredictRepository();
  bool _cargando = true;
  bool _guardando = false;
  bool _confirmando = false;
  String? _error;
  List<PartidoLiga> _partidos = [];
  final Map<int, String> _picks = {};
  EstadoPrediccion? _estado;

  int get _pid => widget.item.participacionId;
  int get _qid => widget.item.quiniela.id;
  bool get _activo => widget.item.activo;
  bool get _confirmada => _estado?.confirmada ?? false;
  bool get _cerrada => _estado?.cerrada(DateTime.now()) ?? false;
  bool get _puedeEditar => _activo && !_confirmada && !_cerrada;
  bool get _completa => _partidos.isNotEmpty && _picks.length >= _partidos.length;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ps = await _repo.getPartidosDeQuiniela(_qid);
      Map<int, String> previas = {};
      EstadoPrediccion? est;
      if (_activo) {
        previas = await _repo.getMisPredicciones(_pid);
        est = await _repo.getMiEstadoPrediccion(_pid);
      }
      if (!mounted) return;
      setState(() {
        _partidos = ps;
        _picks
          ..clear()
          ..addAll(previas);
        _estado = est;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Map<int, String> get _picksValidos {
    final ids = _partidos.map((p) => p.id).toSet();
    return {
      for (final e in _picks.entries)
        if (ids.contains(e.key)) e.key: e.value
    };
  }

  Future<void> _guardar() async {
    final data = _picksValidos;
    if (data.isEmpty) {
      _snack('Elige al menos un resultado.');
      return;
    }
    setState(() => _guardando = true);
    try {
      final n = await _repo.guardarPredicciones(_pid, data);
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack('$n ${n == 1 ? 'predicción guardada' : 'predicciones guardadas'} (borrador).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmar() async {
    if (!_completa) {
      _snack('Completa los ${_partidos.length} partidos antes de confirmar.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmar predicciones?'),
        content: const Text(
            'Al confirmar, tus predicciones se BLOQUEAN y NO podrás cambiarlas. '
            'Se enviarán al panel de la quiniela.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('CONFIRMAR')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _confirmando = true);
    try {
      await _repo.guardarPredicciones(_pid, _picksValidos);
      await _repo.confirmarMisPredicciones(_pid);
      final est = await _repo.getMiEstadoPrediccion(_pid);
      if (!mounted) return;
      setState(() {
        _estado = est;
        _confirmando = false;
      });
      _snack('¡Predicciones confirmadas y bloqueadas!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _nuevaParticipacion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Nueva participación?'),
        content: const Text(
            'Se creará OTRA entrada tuya en esta quiniela (con otro nickname). '
            'El organizador debe confirmarla (cuenta como otro cupo).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('CREAR')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.nuevaParticipacion(_qid);
      if (!mounted) return;
      _snack('Nueva participación creada. El organizador debe confirmarla.');
      Navigator.of(context).pop(true); // volver a la lista para verla
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _verPanel() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PanelLigaScreen(
          quinielaId: _qid, nombre: widget.item.quiniela.nombre),
    ));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.nickname)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ProganaSpacing.lg),
                children: [
                  _cabecera(),
                  const SizedBox(height: ProganaSpacing.sm),
                  _acciones(),
                  const SizedBox(height: ProganaSpacing.lg),
                  _estadoBar(),
                  const SizedBox(height: ProganaSpacing.lg),
                  _aviso(),
                  const SizedBox(height: ProganaSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PARTIDOS', style: ProganaTextStyles.labelLarge),
                      Text('${_picks.length}/${_partidos.length}',
                          style: ProganaTextStyles.scoreMedium),
                    ],
                  ),
                  const SizedBox(height: ProganaSpacing.sm),
                  _lista(),
                ],
              ),
            ),
            if (_puedeEditar && !_cargando && _error == null) _barra(),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final q = widget.item.quiniela;
    return Container(
      padding: ProganaSpacing.cardPaddingLarge,
      decoration: ProganaDecorations.cardGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.nombre, style: ProganaTextStyles.displaySmall),
          const SizedBox(height: ProganaSpacing.sm),
          Row(
            children: [
              _pill('TÚ: ${widget.item.nickname}', ProganaColors.gold),
              const SizedBox(width: 6),
              _pill('MI ESTADO: ${_estadoLabel()}',
                  _activo ? ProganaColors.emerald : ProganaColors.creamDim),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acciones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _verPanel,
            icon: const Icon(Icons.leaderboard, size: 18),
            label: const Text('VER PANEL'),
          ),
        ),
        const SizedBox(width: ProganaSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _nuevaParticipacion,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('OTRA ENTRADA'),
          ),
        ),
      ],
    );
  }

  Widget _estadoBar() {
    final dl = _estado?.deadline;
    final dlTxt = dl != null ? _fmtFecha(dl) : '—';
    Color c;
    String label;
    IconData ic;
    if (!_activo) {
      c = ProganaColors.creamDim;
      label = 'PENDIENTE de confirmación del organizador';
      ic = Icons.hourglass_top;
    } else if (_confirmada) {
      c = ProganaColors.emerald;
      label = 'CONFIRMADA · bloqueada';
      ic = Icons.lock;
    } else if (_cerrada) {
      c = ProganaColors.crimson;
      label = 'CERRADA';
      ic = Icons.lock_clock;
    } else {
      c = ProganaColors.gold;
      label = 'ABIERTA · cierra $dlTxt';
      ic = Icons.timer_outlined;
    }
    return Container(
      padding: ProganaSpacing.cardPadding,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(ic, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: ProganaTextStyles.labelLarge.copyWith(color: c))),
        ],
      ),
    );
  }

  Widget _aviso() {
    String txt;
    if (!_activo) {
      txt = 'El organizador debe confirmarte para poder predecir.';
    } else if (_confirmada) {
      txt = 'Tus predicciones están confirmadas y bloqueadas.';
    } else if (_cerrada) {
      txt = 'La quiniela cerró (1h antes del primer partido).';
    } else {
      txt = 'Elige L / E / V en cada partido. GUARDAR = borrador editable. '
          'CONFIRMAR Y ENVIAR = bloquea todo (irreversible).\n\n'
          'Apoyo Predict (opcional): te da DOS datos para decidir — el equipo '
          'favorito a ganar (para tu L/E/V) y el marcador más probable (el '
          'global, y el que se espera si gana el favorito). Ambos son relevantes; '
          'úsalos juntos. La IA sugiere, tú decides.';
    }
    return Container(
      padding: ProganaSpacing.cardPadding,
      decoration: ProganaDecorations.card,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: ProganaColors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(txt, style: ProganaTextStyles.bodySmall)),
        ],
      ),
    );
  }

  String _estadoLabel() {
    switch (widget.item.miEstado) {
      case 'activo':
        return 'ACTIVO';
      case 'confirmado_plus':
        return 'POR CONFIRMAR';
      default:
        return widget.item.miEstado.toUpperCase();
    }
  }

  Widget _pill(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          border: Border.all(color: c),
          borderRadius: BorderRadius.circular(4),
        ),
        child:
            Text(text, style: ProganaTextStyles.labelSmall.copyWith(color: c)),
      );

  Widget _lista() {
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
          margin: const EdgeInsets.only(bottom: ProganaSpacing.sm),
          padding: ProganaSpacing.cardPadding,
          decoration: ProganaDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ProganaColors.goldOverlay(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        Text('${i + 1}', style: ProganaTextStyles.labelSmall),
                  ),
                  const SizedBox(width: ProganaSpacing.sm),
                  _miniChip(p.competicionCorto),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'J${p.jornada ?? '-'} · ${_fmtFecha(p.fechaHora)}',
                      style: ProganaTextStyles.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _teamsRow(p),
              const SizedBox(height: ProganaSpacing.sm),
              _selectorLEV(p),
              _predictHint(p),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _selectorLEV(PartidoLiga p) {
    final sel = _picks[p.id];
    Widget btn(String v, String label) {
      final activo = sel == v;
      return Expanded(
        child: GestureDetector(
          onTap: _puedeEditar
              ? () => setState(() {
                    if (sel == v) {
                      _picks.remove(p.id);
                    } else {
                      _picks[p.id] = v;
                    }
                  })
              : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo
                  ? ProganaColors.emerald.withValues(alpha: 0.18)
                  : Colors.transparent,
              border: Border.all(
                color: activo
                    ? ProganaColors.emerald
                    : ProganaColors.creamDim.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: ProganaTextStyles.labelLarge.copyWith(
                color: activo
                    ? ProganaColors.emerald
                    : (_puedeEditar
                        ? ProganaColors.cream
                        : ProganaColors.creamDim),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [btn('L', 'L'), btn('E', 'E'), btn('V', 'V')]);
  }

  Widget _barra() {
    return Container(
      padding: const EdgeInsets.all(ProganaSpacing.lg),
      decoration: BoxDecoration(
        color: ProganaColors.midnight2,
        border: Border(
          top: BorderSide(color: ProganaColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (_guardando || _confirmando) ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('GUARDAR'),
            ),
          ),
          const SizedBox(width: ProganaSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  (_guardando || _confirmando || !_completa) ? null : _confirmar,
              icon: _confirmando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock, size: 18),
              label: Text(_completa
                  ? 'CONFIRMAR Y ENVIAR'
                  : 'FALTAN ${_partidos.length - _picks.length}'),
            ),
          ),
        ],
      ),
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

  /// Mapea el corto de la competición → clave de liga de la API Predict.
  String? _ligaKey(String corto) {
    switch (corto.toUpperCase()) {
      case 'LIGAMX':
        return 'ligamx';
      case 'EPL':
        return 'epl';
      case 'BRASILEIRAO':
        return 'brasileirao';
      default:
        return null;
    }
  }

  /// Apoyo compacto de PROGANA Predict bajo el selector (IA sugiere, tú decides).
  /// Failsafe: si la API falla o no hay match → invisible.
  Widget _predictHint(PartidoLiga p) {
    final liga = _ligaKey(p.competicionCorto);
    if (liga == null) return const SizedBox.shrink();
    return FutureBuilder<PredictionResult?>(
      future: _predictRepo.obtenerPrediccion(
          home: p.localNombre, away: p.visitanteNombre, league: liga, season: 2026),
      builder: (ctx, snap) {
        final r = snap.data;
        if (r == null) return const SizedBox.shrink();
        final pct = (r.confidence * 100).round();
        return Container(
          margin: const EdgeInsets.only(top: ProganaSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: ProganaColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                  color: ProganaColors.gold.withValues(alpha: 0.5), width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined,
                      size: 14, color: ProganaColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: ProganaTextStyles.labelSmall
                            .copyWith(color: ProganaColors.creamDim),
                        children: [
                          const TextSpan(text: 'Predict: gana '),
                          TextSpan(
                            text: '${r.pickLabel} · $pct%',
                            style: ProganaTextStyles.labelSmall
                                .copyWith(color: r.pickColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(r.accuracyDisplay,
                      style: ProganaTextStyles.labelSmall
                          .copyWith(color: ProganaColors.emerald)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                r.hasScoreIfPick
                    ? 'Marcador prob. ${r.scoreDisplay}  ·  si gana ${r.scoreIfPickDisplay}'
                    : 'Marcador prob. ${r.scoreDisplay}',
                style: ProganaTextStyles.labelSmall
                    .copyWith(color: ProganaColors.creamDim),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtFecha(DateTime utc) {
    final d = utc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
