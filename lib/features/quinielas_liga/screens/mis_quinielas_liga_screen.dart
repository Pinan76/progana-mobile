import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/quiniela_liga.dart';
import '../repository/quiniela_liga_repository.dart';
import 'crear_quiniela_screen.dart';
import 'detalle_quiniela_liga_screen.dart';

/// Panel del Pro: lista de sus quinielas de clubes.
/// FAB "+ Crear" abre el flujo de creación; tap en una abre su DETALLE.
class MisQuinielasLigaScreen extends StatefulWidget {
  const MisQuinielasLigaScreen({super.key});

  @override
  State<MisQuinielasLigaScreen> createState() => _MisQuinielasLigaScreenState();
}

class _MisQuinielasLigaScreenState extends State<MisQuinielasLigaScreen> {
  final _repo = QuinielaLigaRepository();
  bool _cargando = true;
  String? _error;
  List<QuinielaLiga> _quinielas = [];

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
      final qs = await _repo.misQuinielas();
      if (!mounted) return;
      setState(() {
        _quinielas = qs;
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

  Future<void> _crear() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CrearQuinielaScreen()),
    );
    if (mounted) _cargar(); // refrescar al volver
  }

  Future<void> _abrir(QuinielaLiga q) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalleQuinielaLigaScreen(quiniela: q)),
    );
    if (mounted) _cargar(); // refrescar al volver
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Quinielas de Clubes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        backgroundColor: ProganaColors.gold,
        foregroundColor: ProganaColors.midnight,
        icon: const Icon(Icons.add),
        label: Text('CREAR', style: ProganaTextStyles.button),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState();
    if (_quinielas.isEmpty) return _emptyState();
    return RefreshIndicator(
      onRefresh: _cargar,
      color: ProganaColors.gold,
      backgroundColor: ProganaColors.midnight2,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            ProganaSpacing.md, ProganaSpacing.md, ProganaSpacing.md, 96),
        itemCount: _quinielas.length,
        itemBuilder: (_, i) => _card(_quinielas[i]),
      ),
    );
  }

  Widget _card(QuinielaLiga q) {
    return GestureDetector(
      onTap: () => _abrir(q),
      child: Container(
        margin: const EdgeInsets.only(bottom: ProganaSpacing.sm),
        padding: ProganaSpacing.cardPadding,
        decoration: ProganaDecorations.card,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ProganaColors.goldOverlay(0.12),
                borderRadius: ProganaRadius.button,
              ),
              child: const Icon(Icons.emoji_events,
                  color: ProganaColors.gold, size: 20),
            ),
            const SizedBox(width: ProganaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.nombre,
                    style: ProganaTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${q.codigoInvitacion} · ${q.totalInscritos}/${q.capacidadMaxima ?? '-'} inscritos',
                    style: ProganaTextStyles.labelMedium,
                  ),
                ],
              ),
            ),
            _pillEstado(q.estado),
          ],
        ),
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
        c = ProganaColors.creamDim; // borrador
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProganaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: ProganaColors.gold, size: 48),
            const SizedBox(height: ProganaSpacing.md),
            Text('Aún no tienes quinielas',
                style: ProganaTextStyles.headingMedium),
            const SizedBox(height: ProganaSpacing.xs),
            Text('Crea tu primera quiniela de clubes',
                style: ProganaTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: ProganaSpacing.lg),
            ElevatedButton(
                onPressed: _crear, child: const Text('CREAR QUINIELA')),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProganaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: ProganaTextStyles.bodyMedium),
            const SizedBox(height: ProganaSpacing.md),
            ElevatedButton(
                onPressed: _cargar, child: const Text('REINTENTAR')),
          ],
        ),
      ),
    );
  }
}
