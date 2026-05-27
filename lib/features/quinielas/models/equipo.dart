/// Modelo Equipo - matchea tabla `equipos` en Supabase
/// 
/// L41: Verificado contra information_schema 22 may 2026
class Equipo {
  final int id;
  final String codigo;         // 3 letras: MEX, USA, BRA, etc.
  final String nombre;          // "Mexico", "United States"
  final String? nombreCorto;
  final String? banderaUrl;
  final bool confirmed;
  final int? fifaRanking;
  final String? grupo;          // "A", "B", ... "L"
  final int partidosJugados;
  final int golesAnotados;
  final int golesRecibidos;
  final int victorias;
  final int empates;
  final int derrotas;

  const Equipo({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.nombreCorto,
    this.banderaUrl,
    required this.confirmed,
    this.fifaRanking,
    this.grupo,
    required this.partidosJugados,
    required this.golesAnotados,
    required this.golesRecibidos,
    required this.victorias,
    required this.empates,
    required this.derrotas,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      nombreCorto: json['nombre_corto'] as String?,
      banderaUrl: json['bandera_url'] as String?,
      confirmed: (json['confirmed'] as bool?) ?? false,
      fifaRanking: json['fifa_ranking'] as int?,
      grupo: json['grupo'] as String?,
      partidosJugados: (json['partidos_jugados'] as int?) ?? 0,
      golesAnotados: (json['goles_anotados'] as int?) ?? 0,
      golesRecibidos: (json['goles_recibidos'] as int?) ?? 0,
      victorias: (json['victorias'] as int?) ?? 0,
      empates: (json['empates'] as int?) ?? 0,
      derrotas: (json['derrotas'] as int?) ?? 0,
    );
  }

  /// Emoji bandera basado en código país ISO
  /// (fallback si banderaUrl es null)
  String get emojiBandera {
    final mapping = {
      'MEX': '🇲🇽', 'USA': '🇺🇸', 'CAN': '🇨🇦',
      'BRA': '🇧🇷', 'ARG': '🇦🇷', 'COL': '🇨🇴', 'URU': '🇺🇾',
      'ESP': '🇪🇸', 'FRA': '🇫🇷', 'ITA': '🇮🇹', 'GER': '🇩🇪',
      'POR': '🇵🇹', 'NED': '🇳🇱', 'BEL': '🇧🇪', 'ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'KOR': '🇰🇷', 'JPN': '🇯🇵', 'CZE': '🇨🇿', 'BIH': '🇧🇦',
      'PAR': '🇵🇾', 'QAT': '🇶🇦', 'SUI': '🇨🇭', 'RSA': '🇿🇦',
      'AUS': '🇦🇺', 'CRO': '🇭🇷', 'DEN': '🇩🇰', 'POL': '🇵🇱',
      'SEN': '🇸🇳', 'MAR': '🇲🇦', 'GHA': '🇬🇭', 'CIV': '🇨🇮',
    };
    return mapping[codigo] ?? '⚽';
  }

  @override
  String toString() => 'Equipo($codigo - $nombre)';
}