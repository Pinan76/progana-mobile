import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/partido_liga.dart';
import '../repository/quiniela_liga_repository.dart';

/// Panel de transparencia: picks de todos los participantes (tras el revelado)
/// + aciertos al avanzar los partidos. Antes del cierre: solo tus picks.
class PanelLigaScreen extends StatefulWidget {
  final int quinielaId;
  final String nombre;
  const PanelLigaScreen(
      {super.key, required this.quinielaId, required this.nombre});

  @override
  State<PanelLigaScreen> createState() => _PanelLigaScreenState();
}

class _PanelLigaScreenState extends State<PanelLigaScreen> {
  final _repo = QuinielaLigaRepository();
  bool _cargando = true;
  String? _error;
  PanelEstado? _estado;
  List<PartidoLiga> _partidos = [];
  List<PanelPick> _picks = [];
  List<RankingEntry> _ranking = [];

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
      final est = await _repo.getPanelEstado(widget.quinielaId);
      final parts = await _repo.getPartidosDeQuiniela(widget.quinielaId);
      final picks = await _repo.getPanelPicks(widget.quinielaId);
      List<RankingEntry> rank = [];
      if (est.revelada) {
        rank = await _repo.getRanking(widget.quinielaId);
      }
      if (!mounted) return;
      setState(() {
        _estado = est;
        _partidos = parts;
        _picks = picks;
        _ranking = rank;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel · ${widget.nombre}')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        children: [
          Text(_error!,
              textAlign: TextAlign.center,
              style: ProganaTextStyles.bodyMedium),
          const SizedBox(height: ProganaSpacing.sm),
          Center(
            child: ElevatedButton(
                onPressed: _cargar, child: const Text('REINTENTAR')),
          ),
        ],
      );
    }
    final est = _estado!;
    return ListView(
      padding: const EdgeInsets.all(ProganaSpacing.lg),
      children: [
        _estadoBar(est),
        const SizedBox(height: ProganaSpacing.lg),
        if (!est.revelada) ...[
          _ocultoBanner(est),
          const SizedBox(height: ProganaSpacing.xl),
          Text('TUS PICKS', style: ProganaTextStyles.labelLarge),
          const SizedBox(height: ProganaSpacing.sm),
          _misPicks(),
        ] else ...[
          Text('TABLA GENERAL', style: ProganaTextStyles.labelLarge),
          const SizedBox(height: ProganaSpacing.sm),
          _leaderboard(),
          const SizedBox(height: ProganaSpacing.xl),
          Text('PICKS DE TODOS', style: ProganaTextStyles.labelLarge),
          const SizedBox(height: ProganaSpacing.sm),
          _matriz(),
        ],
        const SizedBox(height: ProganaSpacing.xl),
        Text('PARTIDOS', style: ProganaTextStyles.labelLarge),
        const SizedBox(height: ProganaSpacing.sm),
        _leyendaPartidos(),
      ],
    );
  }

  Widget _leyendaPartidos() {
    if (_partidos.isEmpty) {
      return Text('Sin partidos', style: ProganaTextStyles.bodySmall);
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
              SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: ProganaTextStyles.labelSmall)),
              const SizedBox(width: 6),
              _escudo(p.localEscudo, p.localNombre),
              const SizedBox(width: 6),
              Expanded(
                child: Text(p.localNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProganaTextStyles.bodyMedium),
              ),
              Text(' vs ',
                  style: ProganaTextStyles.labelSmall
                      .copyWith(color: ProganaColors.creamDim)),
              Expanded(
                child: Text(p.visitanteNombre,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProganaTextStyles.bodyMedium),
              ),
              const SizedBox(width: 6),
              _escudo(p.visitanteEscudo, p.visitanteNombre),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _escudo(String? url, String nombre) {
    const double s = 22;
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
              .copyWith(color: ProganaColors.creamDim, fontSize: 9)),
    );
  }

  Widget _estadoBar(PanelEstado est) {
    final c = est.revelada ? ProganaColors.emerald : ProganaColors.gold;
    final txt = est.revelada
        ? 'REVELADA · picks visibles'
        : 'EN CURSO · confirmados ${est.confirmados}/${est.capacidad ?? '-'}';
    return Container(
      padding: ProganaSpacing.cardPadding,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(est.revelada ? Icons.visibility : Icons.lock, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
              child: Text(txt,
                  style: ProganaTextStyles.labelLarge.copyWith(color: c))),
        ],
      ),
    );
  }

  Widget _ocultoBanner(PanelEstado est) {
    final dl = est.deadline;
    final dlTxt = dl != null ? _fmtFecha(dl) : '—';
    return Container(
      padding: ProganaSpacing.cardPaddingLarge,
      decoration: ProganaDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, size: 18, color: ProganaColors.gold),
              const SizedBox(width: 8),
              Text('Picks ocultos hasta el cierre',
                  style: ProganaTextStyles.bodyLarge),
            ],
          ),
          const SizedBox(height: ProganaSpacing.xs),
          Text(
            'Para que sea justo, las selecciones de todos se revelan cuando la '
            'quiniela cierra (1h antes del primer partido, o al llenarse el cupo '
            'con todos confirmados).\n\nCierre: $dlTxt',
            style: ProganaTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _misPicks() {
    final mios = _picks.where((p) => p.esMio).toList();
    if (mios.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        child: Center(
            child: Text('Aún no tienes picks confirmados',
                style: ProganaTextStyles.bodySmall)),
      );
    }
    final byPartido = {for (final p in mios) p.partidoId: p};
    return Column(
      children: _partidos.asMap().entries.map((e) {
        final i = e.key;
        final part = e.value;
        final pick = byPartido[part.id];
        return Container(
          margin: const EdgeInsets.only(bottom: ProganaSpacing.xs),
          padding: ProganaSpacing.cardPadding,
          decoration: ProganaDecorations.card,
          child: Row(
            children: [
              Text('${i + 1}', style: ProganaTextStyles.labelSmall),
              const SizedBox(width: ProganaSpacing.sm),
              Expanded(child: Text(part.titulo, style: ProganaTextStyles.bodyMedium)),
              _celdaPick(pick?.pred, pick?.acierto),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _leaderboard() {
    if (_ranking.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        child: Center(
            child: Text('Sin datos de ranking todavía',
                style: ProganaTextStyles.bodySmall)),
      );
    }
    return Column(
      children: _ranking.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: ProganaSpacing.xs),
          padding: ProganaSpacing.cardPadding,
          decoration: ProganaDecorations.card,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('${r.posicion}',
                    style: ProganaTextStyles.scoreMedium),
              ),
              const SizedBox(width: ProganaSpacing.sm),
              Expanded(
                  child:
                      Text(r.nickname, style: ProganaTextStyles.bodyLarge)),
              Text('${r.aciertos} ✓',
                  style: ProganaTextStyles.labelLarge
                      .copyWith(color: ProganaColors.emerald)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _matriz() {
    if (_picks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        child: Center(
            child:
                Text('Sin picks', style: ProganaTextStyles.bodySmall)),
      );
    }
    // Agrupar por participación preservando orden de aparición
    final orden = <int>[];
    final nombres = <int, String>{};
    final porUsuario = <int, Map<int, PanelPick>>{};
    for (final p in _picks) {
      if (!porUsuario.containsKey(p.participacionId)) {
        porUsuario[p.participacionId] = {};
        orden.add(p.participacionId);
        nombres[p.participacionId] = p.nickname;
      }
      porUsuario[p.participacionId]![p.partidoId] = p;
    }
    // Resultado por partido
    final resultados = <int, String?>{};
    for (final p in _picks) {
      resultados[p.partidoId] = p.resultado;
    }

    const wName = 104.0;
    const wCell = 36.0;

    Widget headerCell(String t, double w, {Color? color}) => Container(
          width: w,
          height: 34,
          alignment: Alignment.center,
          child: Text(t,
              style: ProganaTextStyles.labelSmall
                  .copyWith(color: color ?? ProganaColors.creamDim)),
        );

    final columnas = _partidos;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nombres de columnas (número de partido)
          Row(
            children: [
              headerCell('Participante', wName),
              ...columnas.asMap().entries.map(
                  (e) => headerCell('${e.key + 1}', wCell)),
            ],
          ),
          // Fila de resultados
          Row(
            children: [
              headerCell('Resultado', wName, color: ProganaColors.gold),
              ...columnas.map((part) {
                final r = resultados[part.id];
                return Container(
                  width: wCell,
                  height: 30,
                  alignment: Alignment.center,
                  child: Text(r ?? '·',
                      style: ProganaTextStyles.labelSmall
                          .copyWith(color: ProganaColors.gold)),
                );
              }),
            ],
          ),
          // Filas por participante
          ...orden.map((uid) {
            final picks = porUsuario[uid]!;
            return Row(
              children: [
                Container(
                  width: wName,
                  height: 34,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(nombres[uid] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ProganaTextStyles.bodyMedium),
                ),
                ...columnas.map((part) {
                  final pk = picks[part.id];
                  return _celdaMatriz(pk?.pred, pk?.acierto);
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _celdaMatriz(String? pred, bool? acierto) {
    Color bg = Colors.transparent;
    Color fg = ProganaColors.creamDim;
    if (pred != null) {
      if (acierto == true) {
        bg = ProganaColors.emerald.withValues(alpha: 0.25);
        fg = ProganaColors.emerald;
      } else if (acierto == false) {
        bg = ProganaColors.crimson.withValues(alpha: 0.2);
        fg = ProganaColors.crimson;
      } else {
        fg = ProganaColors.cream;
      }
    }
    return Container(
      width: 36,
      height: 34,
      margin: const EdgeInsets.all(1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(pred ?? '·',
          style: ProganaTextStyles.labelMedium.copyWith(color: fg)),
    );
  }

  Widget _celdaPick(String? pred, bool? acierto) {
    Color c = ProganaColors.creamDim;
    if (acierto == true) c = ProganaColors.emerald;
    if (acierto == false) c = ProganaColors.crimson;
    return Container(
      width: 34,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(pred ?? '·',
          style: ProganaTextStyles.labelLarge.copyWith(color: c)),
    );
  }

  String _fmtFecha(DateTime utc) {
    final d = utc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
