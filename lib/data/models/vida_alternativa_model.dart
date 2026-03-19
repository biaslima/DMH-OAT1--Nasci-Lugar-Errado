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

  VidaAlternativaModel({
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuario_id': usuarioId,
    'pais_code': paisCode,
    'pais_nome': paisNome,
    'capital': capital,
    'idioma': idioma,
    'populacao': populacao,
    'expectativa_vida': expectativaVida,
    'moeda': moeda,
    'clima_nascimento': climaNascimento,
    'bandeira_url': bandeiraUrl,
    'salvo_em': salvoEm,
    'favorita': favorita,
  };

  factory VidaAlternativaModel.fromMap(Map<String, dynamic> map) =>
      VidaAlternativaModel(
        id: map['id'],
        usuarioId: map['usuario_id'],
        paisCode: map['pais_code'],
        paisNome: map['pais_nome'],
        capital: map['capital'],
        idioma: map['idioma'],
        populacao: map['populacao'],
        expectativaVida: map['expectativa_vida'],
        moeda: map['moeda'],
        climaNascimento: map['clima_nascimento'],
        bandeiraUrl: map['bandeira_url'],
        salvoEm: map['salvo_em'],
        favorita: map['favorita'] ?? 0,
      );
}
