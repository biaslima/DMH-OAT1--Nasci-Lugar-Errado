class VidaAlternativaModel {
  final int? id;
  final int usuarioId;
  final String paisCode;
  final String paisNome;
  final String? capital;
  final String? idioma;
  final int? populacao;
  final double? expectativaVida;
  final String? moeda;
  final String? climaNascimento;
  final String? bandeiraUrl;
  final String? salvoEm;
  final int favorita;

  const VidaAlternativaModel({
    this.id,
    required this.usuarioId,
    required this.paisCode,
    required this.paisNome,
    this.capital,
    this.idioma,
    this.populacao,
    this.expectativaVida,
    this.moeda,
    this.climaNascimento,
    this.bandeiraUrl,
    this.salvoEm,
    this.favorita = 0,
  });

  static const String table = 'vidas_alternativas';

  static const String colId = 'id';
  static const String colUsuarioId = 'usuario_id';
  static const String colPaisCode = 'pais_code';
  static const String colPaisNome = 'pais_nome';
  static const String colCapital = 'capital';
  static const String colIdioma = 'idioma';
  static const String colPopulacao = 'populacao';
  static const String colExpectativaVida = 'expectativa_vida';
  static const String colMoeda = 'moeda';
  static const String colClimaNascimento = 'clima_nascimento';
  static const String colBandeiraUrl = 'bandeira_url';
  static const String colSalvoEm = 'salvo_em';
  static const String colFavorita = 'favorita';

  Map<String, dynamic> toMap() {
    return {
      colId: id,
      colUsuarioId: usuarioId,
      colPaisCode: paisCode,
      colPaisNome: paisNome,
      colCapital: capital,
      colIdioma: idioma,
      colPopulacao: populacao,
      colExpectativaVida: expectativaVida,
      colMoeda: moeda,
      colClimaNascimento: climaNascimento,
      colBandeiraUrl: bandeiraUrl,
      colSalvoEm: salvoEm,
      colFavorita: favorita,
    };
  }

  factory VidaAlternativaModel.fromMap(Map<String, dynamic> map) {
    return VidaAlternativaModel(
      id: map[colId] as int?,
      usuarioId: map[colUsuarioId] as int,
      paisCode: map[colPaisCode] as String,
      paisNome: map[colPaisNome] as String,
      capital: map[colCapital] as String?,
      idioma: map[colIdioma] as String?,
      populacao: map[colPopulacao] as int?,
      expectativaVida: (map[colExpectativaVida] as num?)?.toDouble(),
      moeda: map[colMoeda] as String?,
      climaNascimento: map[colClimaNascimento] as String?,
      bandeiraUrl: map[colBandeiraUrl] as String?,
      salvoEm: map[colSalvoEm] as String?,
      favorita: map[colFavorita] as int? ?? 0,
    );
  }

  VidaAlternativaModel copyWith({
    int? id,
    int? usuarioId,
    String? paisCode,
    String? paisNome,
    String? capital,
    String? idioma,
    int? populacao,
    double? expectativaVida,
    String? moeda,
    String? climaNascimento,
    String? bandeiraUrl,
    String? salvoEm,
    int? favorita,
  }) {
    return VidaAlternativaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      paisCode: paisCode ?? this.paisCode,
      paisNome: paisNome ?? this.paisNome,
      capital: capital ?? this.capital,
      idioma: idioma ?? this.idioma,
      populacao: populacao ?? this.populacao,
      expectativaVida: expectativaVida ?? this.expectativaVida,
      moeda: moeda ?? this.moeda,
      climaNascimento: climaNascimento ?? this.climaNascimento,
      bandeiraUrl: bandeiraUrl ?? this.bandeiraUrl,
      salvoEm: salvoEm ?? this.salvoEm,
      favorita: favorita ?? this.favorita,
    );
  }
}
