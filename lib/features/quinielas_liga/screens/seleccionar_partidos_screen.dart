import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/partido_liga.dart';
import '../repository/quiniela_liga_repository.dart';
import 'quiniela_qr_screen.dart';

/// Paso 2: elegir 8-14 partidos (mezcla de ligas) por arrastre o tap.
class SeleccionarPartidosScreen extends StatefulWidget {
  final String nombre;
  final String? descripcion;
  final int capacidad;

  const SeleccionarPartidosScreen({
    super.key,
    required this.nombre,
    required this.descripcion,
    required this.capacidad,
  });

  @override
  State<SeleccionarPartidosScreen> createState() =>
      _SeleccionarPartidosScreenState();
}

class _SeleccionarPartidosScreenState extends State<SeleccionarPartidosScreen> {
  final _repo = QuinielaLigaRepository();

  List<Competicion> _ligas = [];
  int? _ligaSel;
  List<PartidoLiga> _disponibles = [];
  final List<PartidoLiga> _seleccionados = [];

  bool _cargandoLigas = true;
  bool _cargandoPartidos = false;
  bool _creando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarLigas();
  }

  Future<void> _cargarLigas() async {
    try {
      final ligas = await _repo.getCompeticiones();
      if (!mounted) return;
      setState(() {
        _ligas = ligas;
        _cargandoLigas = false;
        if (ligas.isNotEmpty) _ligaSel = ligas.first.id;
      });
      if (_ligaSel != null) _cargarPartidos(_ligaSel!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoLigas = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _cargarPartidos(int ligaId) async {
    setState(() {
      _cargandoPartidos = true;
      _error = null;
    });
    try {
      final partidos = await _repo.getPartidosDisponibles(ligaId);
      if (!mounted) return;
      setState(() {
        _disponibles = partidos;
        _cargandoPartidos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoPartidos = false;
        _error = e.toString();
      });
    }
  }

  bool _yaSel(PartidoLiga p) => _seleccionados.any((s) => s.id == p.id);

  void _agregar(PartidoLiga p) {
    if (_yaSel(p)) return;
    if (_seleccionados.length >= QuinielaLigaRepository.maxPartidos) {
      _snack('Máximo ${QuinielaLigaRepository.maxPartidos} partidos',
          ProganaColors.crimson);
      return;
    }
    setState(() => _seleccionados.add(p));
  }

  void _quitar(PartidoLiga p) =>
      setState(() => _seleccionados.removeWhere((s) => s.id == p.id));

  bool get _valido =>
      _seleccionados.length >= QuinielaLigaRepository.minPartidos &&
      _seleccionados.length <= QuinielaLigaRepository.maxPartidos;

  Future<void> _crear() async {
    if (!_valido) return;
    setState(() => _creando = true);
    try {
      final quiniela = await _repo.crearQuinielaConPartidos(
        nombre: widget.nombre,
        descripcion: widget.descripcion,
        capacidad: widget.capacidad,
        partidoIds: _seleccionados.map((p) => p.id).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuinielaQrScreen(quiniela: quiniela)),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(_msgError(e), ProganaColors.crimson);
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  String _msgError(Object e) {
    final s = e.toString();
    if (s.contains('Pro')) {
      return 'Solo las cuentas Pro pueden crear quinielas.';
    }
    if (s.contains('8') && s.contains('14')) {
      return 'Debes elegir entre 8 y 14 partidos.';
    }
    return 'No se pudo crear la quiniela. Intenta de nuevo.';
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(msg, style: ProganaTextStyles.bodyMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige Partidos')),
      body: SafeArea(
        child: Column(
          children: [
            _chipsLigas(),
            Expanded(child: _listaDisponibles()),
            _panelQuiniela(),
          ],
        ),
      ),
    );
  }

  Widget _chipsLigas() {
    if (_cargandoLigas) {
      return const Padding(
        padding: EdgeInsets.all(ProganaSpacing.md),
        child: LinearProgressIndicator(),
      );
    }
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: ProganaSpacing.md, vertical: ProganaSpacing.xs),
        itemCount: _ligas.length,
        separatorBuilder: (_, _) => const SizedBox(width: ProganaSpacing.xs),
        itemBuilder: (_, i) {
          final liga = _ligas[i];
          final sel = liga.id == _ligaSel;
          return ChoiceChip(
            label: Text(
                liga.nombreCorto.isNotEmpty ? liga.nombreCorto : liga.nombre),
            selected: sel,
            onSelected: (_) {
              setState(() => _ligaSel = liga.id);
              _cargarPartidos(liga.id);
            },
            selectedColor: ProganaColors.gold,
            backgroundColor: ProganaColors.midnight2,
            labelStyle: ProganaTextStyles.labelMedium.copyWith(
              color: sel ? ProganaColors.midnight : ProganaColors.creamDim,
            ),
          );
        },
      ),
    );
  }

  Widget _listaDisponibles() {
    if (_cargandoPartidos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ProganaSpacing.xl),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: ProganaTextStyles.bodyMedium),
        ),
      );
    }
    if (_disponibles.isEmpty) {
      return Center(
        child: Text('No hay partidos próximos en esta liga',
            style: ProganaTextStyles.bodySmall),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(ProganaSpacing.md, ProganaSpacing.xs,
          ProganaSpacing.md, ProganaSpacing.md),
      itemCount: _disponibles.length,
      itemBuilder: (_, i) {
        final p = _disponibles[i];
        final sel = _yaSel(p);
        final card = _cardPartido(p, sel);
        if (sel) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ProganaSpacing.xs),
            child: card,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: ProganaSpacing.xs),
          child: LongPressDraggable<PartidoLiga>(
            data: p,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                  width: 280, child: _cardPartido(p, false, dragging: true)),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: card),
            child: card,
          ),
        );
      },
    );
  }

  Widget _cardPartido(PartidoLiga p, bool sel, {bool dragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ProganaSpacing.md, vertical: ProganaSpacing.sm),
      decoration: BoxDecoration(
        color: dragging ? ProganaColors.midnight3 : ProganaColors.midnight2,
        borderRadius: ProganaRadius.card,
        border: Border.all(
            color: sel ? ProganaColors.emerald : ProganaColors.borderSubtle),
      ),
      child: Row(
        children: [
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
                const SizedBox(height: 6),
                Row(
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
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: sel ? () => _quitar(p) : () => _agregar(p),
            icon: Icon(
              sel ? Icons.check_circle : Icons.add_circle_outline,
              color: sel ? ProganaColors.emerald : ProganaColors.gold,
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

  Widget _panelQuiniela() {
    final n = _seleccionados.length;
    final contadorColor = _valido ? ProganaColors.emerald : ProganaColors.gold;
    return DragTarget<PartidoLiga>(
      onWillAcceptWithDetails: (d) =>
          !_yaSel(d.data) && n < QuinielaLigaRepository.maxPartidos,
      onAcceptWithDetails: (d) => _agregar(d.data),
      builder: (context, candidate, rejected) {
        final activo = candidate.isNotEmpty;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ProganaSpacing.md),
          decoration: BoxDecoration(
            color: ProganaColors.midnight2,
            border: Border(
              top: BorderSide(
                color: activo
                    ? ProganaColors.gold
                    : ProganaColors.gold.withValues(alpha: 0.15),
                width: activo ? 2 : 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TU QUINIELA', style: ProganaTextStyles.labelLarge),
                  Text('$n / ${QuinielaLigaRepository.maxPartidos}',
                      style: ProganaTextStyles.scoreMedium
                          .copyWith(color: contadorColor)),
                ],
              ),
              const SizedBox(height: ProganaSpacing.xs),
              if (n == 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: ProganaSpacing.sm),
                  child: Text(
                      'Arrastra (mantén presionado) o toca + para agregar (mínimo 8)',
                      style: ProganaTextStyles.bodySmall),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          _seleccionados.map((p) => _chipSel(p)).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: ProganaSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_valido && !_creando) ? _crear : null,
                  child: _creando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ProganaColors.midnight),
                        )
                      : Text(_valido
                          ? 'CREAR Y GENERAR QR'
                          : 'ELIGE AL MENOS 8 PARTIDOS'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chipSel(PartidoLiga p) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: ProganaSpacing.xs, vertical: 4),
      decoration: BoxDecoration(
        color: ProganaColors.midnight3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ProganaColors.borderGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${p.localNombre} vs ${p.visitanteNombre}',
              style: ProganaTextStyles.labelMedium
                  .copyWith(color: ProganaColors.cream)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _quitar(p),
            child: const Icon(Icons.close,
                size: 14, color: ProganaColors.crimson),
          ),
        ],
      ),
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
