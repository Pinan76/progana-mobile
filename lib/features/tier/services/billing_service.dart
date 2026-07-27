// =============================================================================
// PROGANA Fantasy — ProganaBilling (in_app_purchase)
// =============================================================================
// Compras de suscripción cross-platform: Google Play Billing (Android) y
// Apple StoreKit (iOS). Verifica cada compra server-side (Edge Function
// verificar-compra) antes de otorgar el tier. NO corre en web (ahí = OpenPay).
//
// Requiere: productos creados en Play Console / App Store Connect con los IDs
// de abajo, y la Edge Function verificar-compra desplegada.
// =============================================================================

library;

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/tier_service.dart';

class ProganaBilling {
  ProganaBilling._();
  static final ProganaBilling instance = ProganaBilling._();

  // IDs — deben COINCIDIR exactamente con los de Play Console / App Store Connect
  static const String plusId = 'progana_plus_mensual';
  static const String proId = 'progana_pro_mensual';
  static const Set<String> _ids = {plusId, proId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _inicializado = false;

  // Callbacks para que la UI reaccione
  void Function(String tier)? onTierActualizado;
  void Function(String mensaje)? onError;
  void Function()? onPendiente;

  /// Inicializa el listener de compras. Devuelve false si la tienda no está
  /// disponible (p. ej. en web o un device sin Play Services).
  Future<bool> init() async {
    if (_inicializado) return true;
    final disponible = await _iap.isAvailable();
    if (!disponible) return false;
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => onError?.call('$e'),
    );
    _inicializado = true;
    return true;
  }

  /// Consulta los detalles (precio localizado, título) de los productos.
  Future<List<ProductDetails>> productos() async {
    final resp = await _iap.queryProductDetails(_ids);
    return resp.productDetails;
  }

  /// Lanza el flujo de compra de una suscripción.
  Future<void> comprar(ProductDetails producto) async {
    final param = PurchaseParam(productDetails: producto);
    // Las suscripciones se compran como non-consumable
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restaura compras previas (iOS lo requiere; Android también lo soporta).
  Future<void> restaurar() async => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      switch (compra.status) {
        case PurchaseStatus.pending:
          onPendiente?.call();
          break;
        case PurchaseStatus.error:
          onError?.call(compra.error?.message ?? 'Error en la compra');
          if (compra.pendingCompletePurchase) await _iap.completePurchase(compra);
          break;
        case PurchaseStatus.canceled:
          if (compra.pendingCompletePurchase) await _iap.completePurchase(compra);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verificar(compra);
          if (ok && compra.pendingCompletePurchase) {
            await _iap.completePurchase(compra);
          }
          break;
      }
    }
  }

  /// Verifica la compra server-side y otorga el tier. NUNCA confiar solo en el
  /// cliente: el token se valida contra Google/Apple en la Edge Function.
  Future<bool> _verificar(PurchaseDetails compra) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'verificar-compra',
        body: {
          'platform': compra.verificationData.source, // google_play / app_store
          'product_id': compra.productID,
          'token': compra.verificationData.serverVerificationData,
        },
      );
      final data = res.data is Map ? res.data as Map : const {};
      if (res.status == 200 && data['ok'] == true) {
        await TierService.instance.cargar(force: true);
        onTierActualizado?.call((data['tier'] as String?) ?? '');
        return true;
      }
      onError?.call('${data['error'] ?? 'No se pudo verificar la compra'}');
      return false;
    } catch (e) {
      onError?.call('Error de verificación: $e');
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _inicializado = false;
  }
}
