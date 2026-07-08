// =============================================================================
// PROGANA Fantasy — OpenpayTokenizeScreen (endurecida)
// =============================================================================
// Abre un WebView con OpenPay.js, inyecta las llaves PÚBLICAS y devuelve el
// token + device_session_id. Robusta contra: asset faltante, onPageFinished
// que no dispara, y errores de red del WebView.
// =============================================================================

library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../config/openpay_config.dart';

class OpenpayToken {
  final String token;
  final String deviceSessionId;
  const OpenpayToken(this.token, this.deviceSessionId);
}

class OpenpayTokenizeScreen extends StatefulWidget {
  const OpenpayTokenizeScreen({super.key});

  @override
  State<OpenpayTokenizeScreen> createState() => _OpenpayTokenizeScreenState();
}

class _OpenpayTokenizeScreenState extends State<OpenpayTokenizeScreen> {
  WebViewController? _controller;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Cargar el HTML y reemplazar los placeholders con la config PÚBLICA
      final raw =
          await rootBundle.loadString('assets/openpay_tokenizer.html');
      final html = raw
          .replaceAll('__MERCHANT_ID__', OpenpayConfig.merchantId)
          .replaceAll('__PUBLIC_KEY__', OpenpayConfig.publicKey)
          .replaceAll('__SANDBOX__', OpenpayConfig.sandbox.toString());

      // 2. Configurar el WebView + canal JS
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(ProganaColors.midnight)
        ..addJavaScriptChannel('FlutterOpenpay', onMessageReceived: _onMessage)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _cargando = false);
            },
            onWebResourceError: (err) {
              debugPrint('WebView error: ${err.errorCode} ${err.description}');
              // No bloqueamos: dejamos que el usuario vea el form si cargó
              if (mounted) setState(() => _cargando = false);
            },
          ),
        )
        // baseUrl da un ORIGEN real a la página (OpenPay.js lo requiere)
        ..loadHtmlString(html, baseUrl: 'https://progana.local/');

      if (!mounted) return;
      setState(() => _controller = controller);

      // 3. Respaldo: si onPageFinished no dispara en 3s, quita el spinner igual
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _cargando) setState(() => _cargando = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el formulario de pago.\n\n$e';
        _cargando = false;
      });
    }
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        final dsi = (data['device_session_id'] as String?) ?? '';
        Navigator.of(context).pop(OpenpayToken(token, dsi));
      }
    } catch (_) {
      // ignorar mensajes no parseables
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProganaColors.midnight,
      appBar: AppBar(
        backgroundColor: ProganaColors.midnight,
        foregroundColor: ProganaColors.cream,
        elevation: 0,
        title: const Text('Pago seguro'),
      ),
      body: Stack(
        children: [
          if (_controller != null && _error == null)
            WebViewWidget(controller: _controller!),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: ProganaColors.crimson, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ProganaColors.cream),
                    ),
                  ],
                ),
              ),
            ),
          if (_cargando && _error == null)
            const Center(
              child: CircularProgressIndicator(color: ProganaColors.gold),
            ),
        ],
      ),
    );
  }
}
