// =============================================================================
// PROGANA Fantasy — NationDisplay (código/inglés → español)
// =============================================================================
//
// L41 COMPLIANT (16 jun 2026):
//   ✓ Réplica en Flutter de NATION_DISPLAY_ES del motor (nations.py)
//   ✓ El motor PROGANA Predict habla INGLÉS (home="Mexico", pick_team="Brazil")
//   ✓ Esta clase traduce a español SOLO para mostrar al usuario
//   ✓ Soporta 2 entradas: código FIFA (MEX) o nombre inglés (Mexico)
//   ✓ Fuente de verdad: NATION_DISPLAY_ES del repo progana-predict (push 19a34bd)
//
// FLUJO:
//   1. Supabase: Equipo(codigo="MEX", nombre="Mexico")
//   2. PredictCard manda al motor: home="Mexico"
//   3. Motor responde: pick_team="Brazil" (inglés canónico)
//   4. NationDisplay.es("Brazil") → "Brasil" para mostrar
//
// =============================================================================

library;

class NationDisplay {
  NationDisplay._();

  /// Mapa código FIFA (3 letras) → nombre español
  /// Usar cuando se tiene el código del Equipo de Supabase.
  static const Map<String, String> _codeToEs = {
    'ALG': 'Argelia',
    'ARG': 'Argentina',
    'AUS': 'Australia',
    'AUT': 'Austria',
    'BEL': 'Bélgica',
    'BIH': 'Bosnia y Herzegovina',
    'BRA': 'Brasil',
    'CAN': 'Canadá',
    'CPV': 'Cabo Verde',
    'COL': 'Colombia',
    'CRO': 'Croacia',
    'CUW': 'Curazao',
    'CZE': 'República Checa',
    'COD': 'RD Congo',
    'ECU': 'Ecuador',
    'EGY': 'Egipto',
    'ENG': 'Inglaterra',
    'FRA': 'Francia',
    'GER': 'Alemania',
    'GHA': 'Ghana',
    'HAI': 'Haití',
    'IRN': 'Irán',
    'IRQ': 'Irak',
    'CIV': 'Costa de Marfil',
    'JPN': 'Japón',
    'JOR': 'Jordania',
    'MEX': 'México',
    'MAR': 'Marruecos',
    'NED': 'Países Bajos',
    'NZL': 'Nueva Zelanda',
    'NOR': 'Noruega',
    'PAN': 'Panamá',
    'PAR': 'Paraguay',
    'POR': 'Portugal',
    'QAT': 'Catar',
    'KSA': 'Arabia Saudita',
    'SCO': 'Escocia',
    'SEN': 'Senegal',
    'RSA': 'Sudáfrica',
    'KOR': 'Corea del Sur',
    'ESP': 'España',
    'SWE': 'Suecia',
    'SUI': 'Suiza',
    'TUN': 'Túnez',
    'TUR': 'Turquía',
    'URU': 'Uruguay',
    'USA': 'Estados Unidos',
    'UZB': 'Uzbekistán',
  };

  /// Mapa nombre inglés canónico → nombre español
  /// Usar cuando el motor devuelve nombres (pick_team="Brazil").
  static const Map<String, String> _enToEs = {
    'Algeria': 'Argelia',
    'Argentina': 'Argentina',
    'Australia': 'Australia',
    'Austria': 'Austria',
    'Belgium': 'Bélgica',
    'Bosnia & Herzegovina': 'Bosnia y Herzegovina',
    'Brazil': 'Brasil',
    'Canada': 'Canadá',
    'Cape Verde': 'Cabo Verde',
    'Colombia': 'Colombia',
    'Croatia': 'Croacia',
    'Curacao': 'Curazao',
    'Czech Republic': 'República Checa',
    'DR Congo': 'RD Congo',
    'Ecuador': 'Ecuador',
    'Egypt': 'Egipto',
    'England': 'Inglaterra',
    'France': 'Francia',
    'Germany': 'Alemania',
    'Ghana': 'Ghana',
    'Haiti': 'Haití',
    'Iran': 'Irán',
    'Iraq': 'Irak',
    'Ivory Coast': 'Costa de Marfil',
    'Japan': 'Japón',
    'Jordan': 'Jordania',
    'Mexico': 'México',
    'Morocco': 'Marruecos',
    'Netherlands': 'Países Bajos',
    'New Zealand': 'Nueva Zelanda',
    'Norway': 'Noruega',
    'Panama': 'Panamá',
    'Paraguay': 'Paraguay',
    'Portugal': 'Portugal',
    'Qatar': 'Catar',
    'Saudi Arabia': 'Arabia Saudita',
    'Scotland': 'Escocia',
    'Senegal': 'Senegal',
    'South Africa': 'Sudáfrica',
    'South Korea': 'Corea del Sur',
    'Spain': 'España',
    'Sweden': 'Suecia',
    'Switzerland': 'Suiza',
    'Tunisia': 'Túnez',
    'Turkey': 'Turquía',
    'Uruguay': 'Uruguay',
    'USA': 'Estados Unidos',
    'Uzbekistan': 'Uzbekistán',
  };

  /// Traduce a español usando el CÓDIGO FIFA del equipo (preferido).
  ///
  /// Ejemplo: NationDisplay.fromCode('MEX') → 'México'
  /// Si el código no se conoce, retorna fallback (o el código mismo).
  static String fromCode(String? code, {String? fallback}) {
    if (code == null || code.isEmpty) return fallback ?? '?';
    return _codeToEs[code.toUpperCase()] ?? fallback ?? code;
  }

  /// Traduce a español usando el nombre INGLÉS que devuelve el motor.
  ///
  /// Ejemplo: NationDisplay.fromEnglish('Brazil') → 'Brasil'
  /// Si no se conoce, retorna el nombre original (fallback seguro).
  static String fromEnglish(String? englishName, {String? fallback}) {
    if (englishName == null || englishName.isEmpty) return fallback ?? '?';
    return _enToEs[englishName] ?? fallback ?? englishName;
  }

  /// Resuelve el mejor display español disponible.
  ///
  /// Prioridad: código FIFA (más confiable) → nombre inglés → fallback.
  static String resolve({
    String? code,
    String? englishName,
    String? fallback,
  }) {
    if (code != null && code.isNotEmpty) {
      final byCode = _codeToEs[code.toUpperCase()];
      if (byCode != null) return byCode;
    }
    if (englishName != null && englishName.isNotEmpty) {
      final byEn = _enToEs[englishName];
      if (byEn != null) return byEn;
    }
    return fallback ?? englishName ?? code ?? '?';
  }
}