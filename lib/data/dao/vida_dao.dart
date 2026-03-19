import 'package:nasci_lugar_errado/data/database_helper.dart';
import 'package:nasci_lugar_errado/data/models/vida_alternativa_model.dart';

class VidaDao {
  final _db = DatabaseHelper();

  Future<int> insert(VidaAlternativaModel vida) async {
    final db = await _db.database;
    return await db.insert('vidas_alternativas', vida.toMap());
  }

  Future<List<VidaAlternativaModel>> getAll(int usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'vidas_alternativas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'salvo_em DESC',
    );
    return result.map((e) => VidaAlternativaModel.fromMap(e)).toList();
  }

  Future<List<VidaAlternativaModel>> getAllByLongevidade(int usuarioId) async {
    final db = await _db.database;
    final result = await db.query(
      'vidas_alternativas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'expectativa_vida DESC',
    );
    return result.map((e) => VidaAlternativaModel.fromMap(e)).toList();
  }

  Future<int> deleteById(int id) async {
    final db = await _db.database;
    return await db.delete(
      'vidas_alternativas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorita(int id, bool favorita) async {
    final db = await _db.database;
    return await db.update(
      'vidas_alternativas',
      {'favorita': favorita ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}