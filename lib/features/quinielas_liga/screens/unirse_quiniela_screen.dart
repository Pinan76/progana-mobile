import 'package:flutter/material.dart';
import '../../../core/theme/progana_theme.dart';
import '../repository/quiniela_liga_repository.dart';

/// Cualquier usuario (Free/Plus/Pro) se une a una quiniela de clubes con
/// el código de invitación (PRG-XXXXXXX). Queda en 'confirmado_plus' a la
/// espera de que el promotor lo confirme.
class UnirseQuinielaScreen extends StatefulWidget {
  const UnirseQuinielaScreen({super.key});

  @override
  State<UnirseQuinielaScreen> createState() => _UnirseQuinielaScreenState();
}

class _UnirseQuinielaScreenState extends State<UnirseQuinielaScreen> {
  final _repo = QuinielaLigaRepository();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      _snack('Escribe el código de invitación.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await _repo.unirsePorCodigo(codigo, nombre: _nombreCtrl.text);
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack('¡Listo! Te uniste. El organizador debe confirmarte.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirme a una quiniela')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ProganaSpacing.lg),
          children: [
            Text('UNIRME CON CÓDIGO', style: ProganaTextStyles.labelLarge),
            const SizedBox(height: ProganaSpacing.xs),
            Text('Pídele el código al organizador (formato PRG-XXXXXXX).',
                style: ProganaTextStyles.bodySmall),
            const SizedBox(height: ProganaSpacing.xl),

            Text('Código de invitación', style: ProganaTextStyles.headingSmall),
            const SizedBox(height: ProganaSpacing.xs),
            TextField(
              controller: _codigoCtrl,
              style: ProganaTextStyles.scoreMedium,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'PRG-XXXXXXX'),
            ),
            const SizedBox(height: ProganaSpacing.lg),

            Text('Tu nombre (opcional)', style: ProganaTextStyles.headingSmall),
            const SizedBox(height: ProganaSpacing.xs),
            TextField(
              controller: _nombreCtrl,
              style: ProganaTextStyles.bodyLarge,
              decoration:
                  const InputDecoration(hintText: 'Para que te reconozcan'),
            ),
            const SizedBox(height: ProganaSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _unirse,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add, size: 20),
                label: Text(_enviando ? 'UNIÉNDOTE...' : 'UNIRME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
