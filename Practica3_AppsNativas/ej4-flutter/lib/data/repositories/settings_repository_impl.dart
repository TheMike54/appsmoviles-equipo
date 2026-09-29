import 'package:sqflite/sqflite.dart';
import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<String?> getValue(String key) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setValue(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
