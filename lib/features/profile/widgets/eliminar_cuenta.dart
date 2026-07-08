// =============================================================================
// PROGANA Fantasy — Eliminar cuenta (helper reutilizable)
// =============================================================================
// Muestra un diálogo de confirmación, llama a la Edge Function eliminar-cuenta,
// cierra sesión y deja que el listener de auth regrese al login.
//
// USO desde profile_screen (o donde quieras el botón):
//   ListTile(
//     leading: const Icon(Icons.delete_forever, color: ProganaColors.crimson),
//     title: const Text('Eliminar mi cuenta'),
//     onTap: () => mostrarDialogoEliminarCuenta(context),
//   )
// =============================================================================

library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/progana_theme.dart';

Future<void> mostrarDialogoEliminarCuenta(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ProganaColors.midnight2,
      title: const Text(
        'Eliminar mi cuenta',
        style: TextStyle(color: ProganaColors.cream),
      ),
      content: const Text(
        'Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos: '
        'predicciones, participaciones y suscripciones. No podrás recuperarlos.\n\n'
        '¿Seguro que deseas continuar?',
        style: TextStyle(color: ProganaColors.creamDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: ProganaColors.creamDim)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Eliminar',
              style: TextStyle(color: ProganaColors.crimson, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmar != true) return;
  if (!context.mounted) return;

  // Overlay de "procesando"
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        const Center(child: CircularProgressIndicator(color: ProganaColors.gold)),
  );

  try {
    final res = await Supabase.instance.client.functions.invoke('eliminar-cuenta');
    final data = res.data is Map ? res.data as Map : const {};
    final ok = res.status == 200 && data['ok'] == true;

    if (!context.mounted) return;
    Navigator.of(context).pop(); // cerrar overlay

    if (ok) {
      await Supabase.instance.client.auth.signOut(); // el listener regresa al login
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta fue eliminada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${data['error'] ?? 'No se pudo eliminar la cuenta'}')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // cerrar overlay
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
