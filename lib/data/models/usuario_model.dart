class UsuarioModel {
  final int? id;
  final String dataNascimento;
  final String paisOrigemCode;
  final String paisOrigemNome;
  final String? criadoEm;

  const UsuarioModel({
    this.id,
    required this.dataNascimento,
    required this.paisOrigemCode,
    required this.paisOrigemNome,
    this.criadoEm,
  });

  static const String table = 'usuarios';

  static const String colId = 'id';
  static const String colDataNascimento = 'data_nascimento';
  static const String colPaisOrigemCode = 'pais_origem_code';
  static const String colPaisOrigemNome = 'pais_origem_nome';
  static const String colCriadoEm = 'criado_em';

  Map<String, dynamic> toMap() {
    return {
      colId: id,
      colDataNascimento: dataNascimento,
      colPaisOrigemCode: paisOrigemCode,
      colPaisOrigemNome: paisOrigemNome,
      colCriadoEm: criadoEm,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map[colId] as int?,
      dataNascimento: map[colDataNascimento] as String,
      paisOrigemCode: map[colPaisOrigemCode] as String,
      paisOrigemNome: map[colPaisOrigemNome] as String,
      criadoEm: map[colCriadoEm] as String?,
    );
  }
}
