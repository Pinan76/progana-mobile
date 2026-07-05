import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../repository/quiniela_liga_repository.dart';
import 'seleccionar_partidos_screen.dart';

/// Paso 1 del flujo del Pro: datos + capacidad (cobro).
/// "Siguiente" lleva a la selección de partidos (la creación ocurre allá).
class CrearQuinielaScreen extends StatefulWidget {
  const CrearQuinielaScreen({super.key});

  @override
  State<CrearQuinielaScreen> createState() => _CrearQuinielaScreenState();
}

class _CrearQuinielaScreenState extends State<CrearQuinielaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '10');

  int get _capacidad => int.tryParse(_capCtrl.text) ?? 0;
  double get _costo => QuinielaLigaRepository.costoEstimado(_capacidad);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeleccionarPartidosScreen(
          nombre: _nombreCtrl.text.trim(),
          descripcion:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          capacidad: _capacidad,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Quiniela')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(ProganaSpacing.lg),
            children: [
              Text('NUEVA QUINIELA DE CLUBES',
                  style: ProganaTextStyles.labelLarge),
              const SizedBox(height: ProganaSpacing.xs),
              Text('Paso 1 de 2 · Datos y capacidad',
                  style: ProganaTextStyles.bodySmall),
              const SizedBox(height: ProganaSpacing.xl),

              _label('Nombre'),
              TextFormField(
                controller: _nombreCtrl,
                style: ProganaTextStyles.bodyLarge,
                decoration:
                    const InputDecoration(hintText: 'Ej. Clásicos del finde'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pon un nombre' : null,
              ),
              const SizedBox(height: ProganaSpacing.lg),

              _label('Descripción (opcional)'),
              TextFormField(
                controller: _descCtrl,
                style: ProganaTextStyles.bodyLarge,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Premios, reglas, de qué trata...'),
              ),
              const SizedBox(height: ProganaSpacing.lg),

              _label('Capacidad (participantes)'),
              TextFormField(
                controller: _capCtrl,
                style: ProganaTextStyles.bodyLarge,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: '10'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Mínimo 1 participante';
                  return null;
                },
              ),
              const SizedBox(height: ProganaSpacing.xl),

              _tarjetaCosto(),
              const SizedBox(height: ProganaSpacing.xxl),

              ElevatedButton(
                onPressed: _siguiente,
                child: const Text('SIGUIENTE: ELEGIR PARTIDOS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: ProganaSpacing.xs),
        child: Text(text, style: ProganaTextStyles.headingSmall),
      );

  Widget _tarjetaCosto() {
    return Container(
      padding: ProganaSpacing.cardPaddingLarge,
      decoration: ProganaDecorations.cardGold,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COSTO ESTIMADO', style: ProganaTextStyles.labelMedium),
              const SizedBox(height: ProganaSpacing.xxs),
              Text(
                '$_capacidad × \$${QuinielaLigaRepository.precioPorParticipante.toStringAsFixed(2)} MXN',
                style: ProganaTextStyles.bodyMedium,
              ),
            ],
          ),
          Text(
            '\$${_costo.toStringAsFixed(2)}',
            style: ProganaTextStyles.scoreLarge
                .copyWith(color: ProganaColors.gold),
          ),
        ],
      ),
    );
  }
}
