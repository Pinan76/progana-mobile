import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../models/quiniela_liga.dart';

/// Muestra el QR del codigo_invitacion para invitar participantes.
class QuinielaQrScreen extends StatelessWidget {
  final QuinielaLiga quiniela;
  const QuinielaQrScreen({super.key, required this.quiniela});

  @override
  Widget build(BuildContext context) {
    final link = quiniela.linkInvitacion;

    return Scaffold(
      appBar: AppBar(title: const Text('Comparte tu Quiniela')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ProganaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                quiniela.nombre,
                textAlign: TextAlign.center,
                style: ProganaTextStyles.displaySmall,
              ),
              const SizedBox(height: ProganaSpacing.xs),
              Text(
                'Escanea o comparte el enlace para invitar',
                textAlign: TextAlign.center,
                style: ProganaTextStyles.bodySmall,
              ),
              const SizedBox(height: ProganaSpacing.xxl),

              // QR sobre fondo claro (mejor escaneo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(ProganaSpacing.lg),
                  decoration: BoxDecoration(
                    color: ProganaColors.cream,
                    borderRadius: ProganaRadius.cardLarge,
                    border: Border.all(color: ProganaColors.gold, width: 2),
                  ),
                  child: QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: ProganaColors.cream,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: ProganaColors.midnight,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: ProganaColors.midnight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ProganaSpacing.xl),

              // Código de invitación (tap para copiar)
              GestureDetector(
                onTap: () => _copiar(
                  context,
                  quiniela.codigoInvitacion,
                  'Código copiado',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: ProganaSpacing.md,
                    horizontal: ProganaSpacing.lg,
                  ),
                  decoration: ProganaDecorations.card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        quiniela.codigoInvitacion,
                        style: ProganaTextStyles.scoreMedium.copyWith(
                          color: ProganaColors.emerald,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: ProganaSpacing.xs),
                      const Icon(Icons.copy,
                          color: ProganaColors.creamDim, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ProganaSpacing.md),

              // Copiar enlace (botón gold del tema)
              ElevatedButton.icon(
                onPressed: () => _copiar(context, link, 'Enlace copiado'),
                icon: const Icon(Icons.link, size: 20),
                label: const Text('COPIAR ENLACE'),
              ),
              const SizedBox(height: ProganaSpacing.xs),

              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('LISTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copiar(BuildContext context, String texto, String mensaje) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ProganaColors.emeraldDeep,
        content: Text(mensaje, style: ProganaTextStyles.bodyMedium),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
