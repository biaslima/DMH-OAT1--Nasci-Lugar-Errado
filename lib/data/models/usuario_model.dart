class UsuarioModel {
  final int? id;
  final String dataNascimento;
  final String paisOrigemCode;
  final String paisOrigemNome;
  final String? criadoEm;

  UsuarioModel({
    this.id,
    required this.dataNascimento,
    required this.paisOrigemCode,
    required this.paisOrigemNome,
    this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'data_nascimento': dataNascimento,
    'pais_origem_code': paisOrigemCode,
    'pais_origem_nome': paisOrigemNome,
    'criado_em': criadoEm,
  };

  factory UsuarioModel.fromMap(Map<String, dynamic> map) => UsuarioModel(
    id: map['id'],
    dataNascimento: map['data_nascimento'],
    paisOrigemCode: map['pais_origem_code'],
    paisOrigemNome: map['pais_origem_nome'],
    criadoEm: map['criado_em'],
  );
}
