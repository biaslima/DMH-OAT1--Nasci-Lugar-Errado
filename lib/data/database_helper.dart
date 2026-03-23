import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Getter: retorna o banco já aberto ou abre pela primeira vez
  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Pega o caminho da pasta de dados do app no celular
    final path = join(await getDatabasesPath(), 'nasceu_lugar_errado.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_nascimento TEXT NOT NULL,
        pais_origem_code TEXT NOT NULL,
        pais_origem_nome TEXT NOT NULL,
        criado_em TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE TABLE historico_buscas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        vida_id INTEGER NOT NULL,
        buscado_em TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (vida_id) REFERENCES vidas_alternativas(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
