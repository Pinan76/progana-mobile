// =============================================================================
// PROGANA Fantasy — OpenpayConfig (CLIENTE)
// =============================================================================
// SOLO datos PÚBLICOS de OpenPay (seguros de embeber en la app):
//   · merchantId  → identificador del comercio
//   · publicKey   → llave PÚBLICA (pk_...) para tokenizar. NO es secreta.
//   · sandbox     → true en pruebas, false en producción
//
// 🔒 La llave PRIVADA (sk_...) NUNCA va aquí — vive solo en los Secrets de la
//    Edge Function crear-suscripcion.
// =============================================================================

library;

class OpenpayConfig {
  OpenpayConfig._();

  /// Merchant ID de OpenPay (visto en tus logs; confírmalo en Configuración).
  static const String merchantId = 'mlndnhhcnxvzlnoaxs4i';

  /// Llave PÚBLICA de OpenPay (pk_...). Sácala de OpenPay → Configuración → API.
  /// Es pública por diseño (se usa en el cliente para tokenizar). NO es secreta.
  static const String publicKey = 'pk_a519ed40f3c448feb246a4b8ed9f2dd3';

  /// true en sandbox, false en producción.
  static const bool sandbox = true;
}
