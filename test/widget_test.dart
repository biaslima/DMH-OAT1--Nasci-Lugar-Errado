import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite/sqflite.dart';
import 'package:nasci_lugar_errado/data/database_helper.dart';
import 'package:nasci_lugar_errado/data/dao/usuario_dao.dart';
import 'package:nasci_lugar_errado/data/dao/vida_dao.dart';
import 'package:nasci_lugar_errado/data/models/usuario_model.dart';
import 'package:nasci_lugar_errado/data/models/vida_alternativa_model.dart';

void main() {
  // Roda uma vez antes de todos os testes
  setUpAll(() {
    sqfliteFfiInit();
  });

  // Roda antes de cada teste individual
  setUp(() async {
    // Usa banco em memória — não salva nada no disco
    databaseFactory = databaseFactoryFfi;
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
  });

  test('Deve inserir e buscar um usuário', () async {
    final dao = UsuarioDao();

    // Cria um usuário de teste
    final usuario = UsuarioModel(
      dataNascimento: '1999-07-14',
      paisOrigemCode: 'BR',
      paisOrigemNome: 'Brasil',
    );

    // Insere no banco e pega o id gerado
    final id = await dao.insert(usuario);

    // Verifica que o id foi gerado (maior que 0)
    expect(id, greaterThan(0));

    // Busca pelo id e verifica os dados
    final encontrado = await dao.getById(id);
    expect(encontrado, isNotNull);
    expect(encontrado!.paisOrigemCode, equals('BR'));
    expect(encontrado.dataNascimento, equals('1999-07-14'));

    print('✅ Usuário inserido com id: $id');
  });

  test('Deve inserir e buscar uma vida alternativa', () async {
    final usuarioDao = UsuarioDao();
    final vidaDao = VidaDao();

    // Primeiro cria um usuário (necessário por causa do FOREIGN KEY)
    final usuarioId = await usuarioDao.insert(
      UsuarioModel(
        dataNascimento: '1999-07-14',
        paisOrigemCode: 'BR',
        paisOrigemNome: 'Brasil',
      ),
    );

    // Cria uma vida alternativa vinculada ao usuário
    final vida = VidaAlternativaModel(
      usuarioId: usuarioId,
      paisCode: 'JP',
      paisNome: 'Japão',
      capital: 'Tóquio',
      idioma: 'Japonês',
      expectativaVida: 84.3,
      moeda: 'Yen (JPY)',
    );

    final vidaId = await vidaDao.insert(vida);
    expect(vidaId, greaterThan(0));

    // Busca todas as vidas do usuário
    final vidas = await vidaDao.getAll(usuarioId);
    expect(vidas.length, equals(1));
    expect(vidas.first.paisCode, equals('JP'));
    expect(vidas.first.expectativaVida, equals(84.3));

    print('✅ Vida alternativa inserida com id: $vidaId');
  });

  test('Deve deletar uma vida alternativa', () async {
    final usuarioDao = UsuarioDao();
    final vidaDao = VidaDao();

    final usuarioId = await usuarioDao.insert(
      UsuarioModel(
        dataNascimento: '2000-01-01',
        paisOrigemCode: 'BR',
        paisOrigemNome: 'Brasil',
      ),
    );

    final vidaId = await vidaDao.insert(
      VidaAlternativaModel(
        usuarioId: usuarioId,
        paisCode: 'FR',
        paisNome: 'França',
      ),
    );

    // Deleta e verifica que sumiu
    await vidaDao.deleteById(vidaId);
    final vidas = await vidaDao.getAll(usuarioId);
    expect(vidas.isEmpty, isTrue);

    print('✅ Vida deletada com sucesso');
  });

  test('Deve favoritar e desfavoritar uma vida', () async {
    final usuarioDao = UsuarioDao();
    final vidaDao = VidaDao();

    final usuarioId = await usuarioDao.insert(
      UsuarioModel(
        dataNascimento: '1995-03-20',
        paisOrigemCode: 'BR',
        paisOrigemNome: 'Brasil',
      ),
    );

    final vidaId = await vidaDao.insert(
      VidaAlternativaModel(
        usuarioId: usuarioId,
        paisCode: 'IS',
        paisNome: 'Islândia',
      ),
    );

    // Favorita
    await vidaDao.toggleFavorita(vidaId, true);
    var vidas = await vidaDao.getAll(usuarioId);
    expect(vidas.first.favorita, equals(1));
    print('✅ Vida favoritada');

    // Desfavorita
    await vidaDao.toggleFavorita(vidaId, false);
    vidas = await vidaDao.getAll(usuarioId);
    expect(vidas.first.favorita, equals(0));
    print('✅ Vida desfavoritada');
  });
}
