// =============================================================================
// PROGANA Fantasy — OpenpayTokenizeScreen
// =============================================================================
// Abre un WebView con la página OpenPay.js, inyecta las llaves PÚBLICAS, y al
// tokenizar la tarjeta devuelve (via Navigator.pop) un OpenpayToken con el
// token + device_session_id. La tarjeta vive solo dentro del WebView de OpenPay.
//
// Requiere el paquete webview_flutter (ver pubspec) + permiso INTERNET (Android).
// =============================================================================

library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/progana_theme.dart';
import '../config/openpay_config.dart';

/// Resultado de la tokenización.
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Cargar el HTML y reemplazar los placeholders con la config PÚBLICA
    final raw =
        await rootBundle.loadString('assets/openpay_tokenizer.html');
    final html = raw
        .replaceAll('__MERCHANT_ID__', OpenpayConfig.merchantId)
        .replaceAll('__PUBLIC_KEY__', OpenpayConfig.publicKey)
        .replaceAll('__SANDBOX__', OpenpayConfig.sandbox.toString());

    // 2. Configurar el WebView + canal JS para recibir el token
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterOpenpay', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _cargando = false);
          },
        ),
      )
      ..loadHtmlString(html);

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _onMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        final dsi = (data['device_session_id'] as String?) ?? '';
        Navigator.of(context).pop(OpenpayToken(token, dsi));
      }
    } catch (_) {
      // mensaje no parseable → ignorar (los errores se muestran dentro del WebView)
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
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_cargando)
            const Center(
              child: CircularProgressIndicator(color: ProganaColors.gold),
            ),
        ],
      ),
    );
  }
}
