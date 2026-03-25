import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _dbName = 'nasceu_lugar_errado.db';
  static const int _dbVersion = 1;

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createUsuariosTable);
    await db.execute(_createVidasTable);
    await db.execute(_createHistoricoTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  static const String _createUsuariosTable = '''
    CREATE TABLE usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_nascimento TEXT NOT NULL,
      pais_origem_code TEXT NOT NULL,
      pais_origem_nome TEXT NOT NULL,
      criado_em TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  static const String _createVidasTable = '''
    CREATE TABLE vidas_alternativas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL,
      pais_code TEXT NOT NULL,
      pais_nome TEXT NOT NULL,
      capital TEXT,
      idioma TEXT,
      populacao INTEGER,
      expectativa_vida REAL,
      moeda TEXT,
      clima_nascimento TEXT,
      bandeira_url TEXT,
      salvo_em TEXT DEFAULT CURRENT_TIMESTAMP,
      favorita INTEGER DEFAULT 0,
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    )
  ''';

  static const String _createHistoricoTable = '''
    CREATE TABLE historico_buscas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL,
      vida_id INTEGER NOT NULL,
      buscado_em TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
      FOREIGN KEY (vida_id) REFERENCES vidas_alternativas(id)
    )
  ''';
}
