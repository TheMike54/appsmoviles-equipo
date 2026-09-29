import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/media_item.dart';
import '../../domain/models/media_type.dart';
import '../../domain/repositories/media_repository.dart';
import '../db/app_database.dart';

class MediaRepositoryImpl implements MediaRepository {
  final _random = Random();

  Future<Directory> _folderFor(MediaType type) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final sub = type == MediaType.photo ? 'fotos' : 'audios';
    final dir = Directory(p.join(documentsDir.path, 'ej4_flutter', sub));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _uniqueFileName(String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = _random.nextInt(1000000);
    return '${timestamp}_$suffix.$extension';
  }

  MediaItem _fromRow(Map<String, Object?> row) {
    return MediaItem(
      id: row['id'] as int,
      type: MediaTypeStorage.fromDbValue(row['type'] as String),
      filePath: row['filePath'] as String,
      album: row['album'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
      filter: row['filter'] as String?,
      durationMs: row['durationMs'] as int?,
    );
  }

  Map<String, Object?> _toRow(MediaItem item) {
    return {
      'type': item.type.toDbValue(),
      'filePath': item.filePath,
      'album': item.album,
      'createdAt': item.createdAt.toIso8601String(),
      'filter': item.filter,
      'durationMs': item.durationMs,
    };
  }

  @override
  Future<List<MediaItem>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('media', orderBy: 'createdAt DESC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<String>> getAlbums() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('albums', orderBy: 'name ASC');
    final names = rows.map((r) => r['name'] as String).toList();
    if (!names.contains(AppDatabase.defaultAlbum)) {
      names.insert(0, AppDatabase.defaultAlbum);
    }
    return names;
  }

  @override
  Future<void> createAlbum(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final db = await AppDatabase.instance.database;
    await db.insert(
      'albums',
      {'name': trimmed},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<MediaItem> saveNewMedia({
    required File sourceFile,
    required MediaType type,
    required String album,
    String? filter,
    int? durationMs,
  }) async {
    final folder = await _folderFor(type);
    final extension = p.extension(sourceFile.path).replaceFirst('.', '');
    final fileName = _uniqueFileName(extension.isEmpty
        ? (type == MediaType.photo ? 'jpg' : 'm4a')
        : extension);
    final destination = File(p.join(folder.path, fileName));
    await sourceFile.copy(destination.path);

    await createAlbum(album);

    final item = MediaItem(
      type: type,
      filePath: destination.path,
      album: album,
      createdAt: DateTime.now(),
      filter: filter,
      durationMs: durationMs,
    );

    final db = await AppDatabase.instance.database;
    final id = await db.insert('media', _toRow(item));
    return item.copyWith(id: id);
  }

  @override
  Future<void> update(MediaItem item) async {
    if (item.id == null) return;
    await createAlbum(item.album);
    final db = await AppDatabase.instance.database;
    await db.update(
      'media',
      _toRow(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> delete(MediaItem item) async {
    final db = await AppDatabase.instance.database;
    await db.delete('media', where: 'id = ?', whereArgs: [item.id]);
    final file = File(item.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
