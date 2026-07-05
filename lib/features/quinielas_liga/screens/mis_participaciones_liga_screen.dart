import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/mi_quiniela_liga.dart';
import '../repository/quiniela_liga_repository.dart';
import 'unirse_quiniela_screen.dart';
import 'participante_detalle_liga_screen.dart';

/// Lado PARTICIPANTE: quinielas de clubes donde estoy inscrito.
class MisParticipacionesLigaScreen extends StatefulWidget {
  const MisParticipacionesLigaScreen({super.key});

  @override
  State<MisParticipacionesLigaScreen> createState() =>
      _MisParticipacionesLigaScreenState();
}

class _MisParticipacionesLigaScreenState
    extends State<MisParticipacionesLigaScreen> {
  final _repo = QuinielaLigaRepository();
  bool _cargando = true;
  String? _error;
  List<MiQuinielaLiga> _items = [];

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
      final items = await _repo.misParticipaciones();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _unirse() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UnirseQuinielaScreen()),
    );
    _cargar(); // refrescar al volver
  }

  void _abrir(MiQuinielaLiga item) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ParticipanteDetalleLigaScreen(item: item),
        ))
        .then((_) => _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quinielas donde participo')),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(ProganaSpacing.lg),
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _unirse,
              icon: const Icon(Icons.group_add, size: 20),
              label: const Text('UNIRME CON CÓDIGO'),
            ),
          ),
          const SizedBox(height: ProganaSpacing.xl),
          if (_error != null) ...[
            Text(_error!,
                textAlign: TextAlign.center,
                style: ProganaTextStyles.bodyMedium),
            const SizedBox(height: ProganaSpacing.sm),
            Center(
              child: ElevatedButton(
                  onPressed: _cargar, child: const Text('REINTENTAR')),
            ),
          ] else if (_items.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(ProganaSpacing.xl),
              child: Center(
                child: Text(
                  'Aún no participas en ninguna quiniela de clubes.\nÚnete con un código.',
                  textAlign: TextAlign.center,
                  style: ProganaTextStyles.bodySmall,
                ),
              ),
            ),
          ] else
            ..._items.map(_fila),
        ],
      ),
    );
  }

  Widget _fila(MiQuinielaLiga item) {
    final q = item.quiniela;
    return GestureDetector(
      onTap: () => _abrir(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: ProganaSpacing.sm),
        padding: ProganaSpacing.cardPadding,
        decoration: ProganaDecorations.card,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.nombre, style: ProganaTextStyles.bodyLarge),
                  const SizedBox(height: 2),
                  Text('Tú: ${item.nickname}',
                      style: ProganaTextStyles.labelMedium
                          .copyWith(color: ProganaColors.gold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _miEstadoPill(item.miEstado),
                      if (item.confirmada) ...[
                        const SizedBox(width: 6),
                        _miEstadoPill('_confirmada'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: ProganaColors.creamDim),
          ],
        ),
      ),
    );
  }

  Widget _miEstadoPill(String estado) {
    late Color c;
    late String label;
    switch (estado) {
      case 'activo':
        c = ProganaColors.emerald;
        label = 'ACTIVO';
        break;
      case '_confirmada':
        c = ProganaColors.emerald;
        label = 'CONFIRMADA';
        break;
      case 'confirmado_plus':
        c = ProganaColors.gold;
        label = 'POR CONFIRMAR';
        break;
      default:
        c = ProganaColors.creamDim;
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
}
