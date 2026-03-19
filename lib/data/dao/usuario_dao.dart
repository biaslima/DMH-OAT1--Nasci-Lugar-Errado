import 'package:nasci_lugar_errado/data/database_helper.dart';
import 'package:nasci_lugar_errado/data/models/usuario_model.dart';

class UsuarioDao {
  final _db = DatabaseHelper();

  Future<int> insert(UsuarioModel usuario) async {
    final db = await _db.database;
    return await db.insert('usuarios', usuario.toMap());
  }

  Future<UsuarioModel?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UsuarioModel.fromMap(result.first);
  }

  Future<UsuarioModel?> getLast() async {
    final db = await _db.database;
    final result = await db.query('usuarios', orderBy: 'id DESC', limit: 1);

    if (result.isEmpty) return null;
    return UsuarioModel.fromMap(result.first);
  }
}
