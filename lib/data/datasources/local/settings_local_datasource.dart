import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsLocalDatasource {
  Future<Database> get _db => DatabaseHelper.database;

  Future<String?> getSetting(String key) async {
    final db = await _db;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastSyncTime(String table) async {
    final db = await _db;
    final maps = await db.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [table],
    );
    if (maps.isEmpty) return null;
    final value = maps.first['last_synced_at'] as String?;
    if (value == null) return null;
    return DateTime.parse(value);
  }

  Future<void> setLastSyncTime(String table, DateTime time) async {
    final db = await _db;
    await db.insert(
      'sync_metadata',
      {'table_name': table, 'last_synced_at': time.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
