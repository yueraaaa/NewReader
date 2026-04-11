import 'package:sqflite/sqflite.dart';
import '../datasources/remote/supabase_datasource.dart';

class SyncService {
  final SupabaseDatasource _remoteDatasource;
  final Database _localDb;

  SyncService(this._remoteDatasource, this._localDb);

  // Get last sync time for a table from sync_metadata
  Future<DateTime?> _getLastSyncTime(String table) async {
    final result = await _localDb.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [table],
    );
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['last_sync'] as String);
  }

  // Update last sync time for a table
  Future<void> _updateLastSyncTime(String table, DateTime syncTime) async {
    await _localDb.insert(
      'sync_metadata',
      {'table_name': table, 'last_sync': syncTime.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch remote changes since last sync
  Future<List<Map<String, dynamic>>> getChangesSince(
    String table,
    DateTime? lastSync,
  ) async {
    final since = lastSync?.toIso8601String();
    switch (table) {
      case 'feeds':
        return await _remoteDatasource.getFeeds(since);
      case 'articles':
        return await _remoteDatasource.getArticles(since);
      case 'categories':
        return await _remoteDatasource.getCategories(since);
      default:
        return [];
    }
  }

  // Push local changes to remote
  Future<void> pushChanges(
    String table,
    List<Map<String, dynamic>> localChanges,
  ) async {
    for (final change in localChanges) {
      switch (table) {
        case 'feeds':
          await _remoteDatasource.upsertFeed(change);
          break;
        case 'articles':
          await _remoteDatasource.upsertArticle(change);
          break;
        case 'categories':
          await _remoteDatasource.upsertCategory(change);
          break;
      }
    }
  }

  // Apply remote changes to local DB with last-write-wins conflict resolution
  Future<void> _applyRemoteChanges(
    String table,
    List<Map<String, dynamic>> remoteChanges,
  ) async {
    for (final remoteChange in remoteChanges) {
      final remoteUpdatedAt = DateTime.parse(remoteChange['updated_at'] as String);

      // Check if local record exists
      final localRecords = await _localDb.query(
        table,
        where: 'id = ?',
        whereArgs: [remoteChange['id']],
      );

      if (localRecords.isEmpty) {
        // No local record, insert remote
        await _localDb.insert(table, remoteChange);
      } else {
        // Compare updated_at timestamps - last write wins
        final localUpdatedAt = DateTime.parse(localRecords.first['updated_at'] as String);
        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          // Remote is newer, update local
          await _localDb.update(
            table,
            remoteChange,
            where: 'id = ?',
            whereArgs: [remoteChange['id']],
          );
        }
      }
    }
  }

  // Get local changes since last sync
  Future<List<Map<String, dynamic>>> _getLocalChangesSince(
    String table,
    DateTime? lastSync,
  ) async {
    if (lastSync == null) {
      return await _localDb.query(table);
    }
    return await _localDb.query(
      table,
      where: 'updated_at > ?',
      whereArgs: [lastSync.toIso8601String()],
    );
  }

  // Sync a single table
  Future<void> _syncTable(String table) async {
    final lastSync = await _getLastSyncTime(table);

    // Step 1: Get remote changes since last sync
    final remoteChanges = await getChangesSince(table, lastSync);

    // Step 2: Apply remote changes to local (with last-write-wins)
    await _applyRemoteChanges(table, remoteChanges);

    // Step 3: Get local changes since last sync
    final localChanges = await _getLocalChangesSince(table, lastSync);

    // Step 4: Push local changes to remote
    await pushChanges(table, localChanges);

    // Step 5: Update last sync time
    await _updateLastSyncTime(table, DateTime.now());
  }

  // Sync all tables
  Future<void> syncAll() async {
    await _syncTable('feeds');
    await _syncTable('articles');
    await _syncTable('categories');
  }
}
