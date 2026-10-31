import 'package:sqflite/sqflite.dart';

/// Data Access Object responsible for exporting local user data to Cloud JSON
/// and transactionally merging cloud payloads with dynamic schema resilience.
class CloudSyncDao {
  final Future<Database> Function() _getDatabase;

  CloudSyncDao(this._getDatabase);

  /// Exports all user data tables to a structured JSON payload (format_version: 2).
  Future<Map<String, dynamic>> exportCloudSyncData() async {
    final db = await _getDatabase();
    return {
      'format_version': 2,
      'user_dexes': await db.query('user_dexes'),
      'folders': await db.query('folders'),
      'folder_structure': await db.query('folder_structure'),
      'user_pokemon': await db.query('user_pokemon'),
      'shiny_hunts': await db.query('shiny_hunts'),
    };
  }

  /// Merges remote cloud data into local SQLite tables within an atomic transaction.
  /// Dynamically queries `PRAGMA table_info` to tolerate missing tables or future columns.
  Future<void> mergeCloudSyncData(Map<String, dynamic> cloudData) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON;');

      final Map<String, Set<String>> cachedColumns = {};
      Future<Set<String>> getLocalColumns(String table) async {
        if (cachedColumns.containsKey(table)) return cachedColumns[table]!;
        final info = await txn.rawQuery("PRAGMA table_info('$table')");
        final cols = info.map((r) => r['name'].toString().toLowerCase()).toSet();
        cachedColumns[table] = cols;
        return cols;
      }

      Future<void> mergeTable(
        String tableName,
        List<String> primaryKeys,
        List<dynamic>? remoteRows,
      ) async {
        if (remoteRows == null) return;
        final localCols = await getLocalColumns(tableName);
        if (localCols.isEmpty) return; // Table not present in local schema, skip safely

        for (var row in remoteRows) {
          final remoteRow = Map<String, dynamic>.from(row as Map);
          final filteredRow = <String, dynamic>{};
          for (final entry in remoteRow.entries) {
            if (localCols.contains(entry.key.toLowerCase())) {
              filteredRow[entry.key] = entry.value;
            }
          }

          bool hasAllPks = true;
          for (final pk in primaryKeys) {
            if (!filteredRow.containsKey(pk)) {
              hasAllPks = false;
              break;
            }
          }
          if (!hasAllPks) continue;

          final whereClause = primaryKeys.map((k) => '$k = ?').join(' AND ');
          final whereArgs = primaryKeys.map((k) => filteredRow[k]).toList();

          final localResult = await txn.query(
            tableName,
            where: whereClause,
            whereArgs: whereArgs,
          );

          if (localResult.isEmpty) {
            await txn.insert(tableName, filteredRow);
          } else {
            final localRow = localResult.first;
            final localUpdated = (localRow['updated_at'] as num?)?.toInt() ?? 0;
            final remoteUpdated =
                (filteredRow['updated_at'] as num?)?.toInt() ?? 0;
            if (remoteUpdated > localUpdated) {
              await txn.update(
                tableName,
                filteredRow,
                where: whereClause,
                whereArgs: whereArgs,
              );
            }
          }
        }
      }

      // Order of syncing respects foreign keys
      await mergeTable('folders', ['id'], cloudData['folders'] as List?);
      await mergeTable('user_dexes', ['id'], cloudData['user_dexes'] as List?);
      await mergeTable('folder_structure', [
        'parent_id',
        'child_id',
      ], cloudData['folder_structure'] as List?);
      await mergeTable('shiny_hunts', ['id'], cloudData['shiny_hunts'] as List?);
      await mergeTable('user_pokemon', [
        'dex_id',
        'unique_id',
      ], cloudData['user_pokemon'] as List?);
    });
  }
}
