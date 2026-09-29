import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/constants.dart';

/// Envoltorio único de la base sqflite de la app.
/// - `media`: metadatos de fotos y audios.
/// - `albums`: nombres de álbumes (para que uno recién creado y vacío exista).
/// - `settings`: preferencias simples (como el tema elegido), clave/valor.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String defaultAlbum = kDefaultAlbum;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'ej4_flutter.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE media (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            filePath TEXT NOT NULL,
            album TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            filter TEXT,
            durationMs INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE albums (
            name TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.insert('albums', {'name': defaultAlbum});
      },
    );
  }
}
