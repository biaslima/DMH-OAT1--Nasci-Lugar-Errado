import 'package:nasci_lugar_errado/data/database_helper.dart';
import 'package:nasci_lugar_errado/data/models/vida_alternativa_model.dart';

class VidaDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String _table = 'vidas_alternativas';

  Future<int> insert(VidaAlternativaModel vida) async {
    final db = await _databaseHelper.database;
    return db.insert(_table, vida.toMap());
  }

  Future<List<VidaAlternativaModel>> getAll(int usuarioId) {
    return _getByUsuario(usuarioId, orderBy: 'salvo_em DESC');
  }

  Future<List<VidaAlternativaModel>> getAllByLongevidade(int usuarioId) {
    return _getByUsuario(usuarioId, orderBy: 'expectativa_vida DESC');
  }

  Future<int> deleteById(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorita(int id, bool favorita) async {
    final db = await _databaseHelper.database;
    return db.update(
      _table,
      {'favorita': favorita ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<VidaAlternativaModel>> _getByUsuario(
    int usuarioId, {
    required String orderBy,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      _table,
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: orderBy,
    );

    return result.map(VidaAlternativaModel.fromMap).toList();
  }
}
