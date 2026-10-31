import 'package:sqflite/sqflite.dart';
import '../../models/shiny_hunt.dart';

/// Data Access Object for Shiny Hunts persisted in `user_data.sqlite`.
class ShinyHuntDao {
  final Future<Database> Function() _getDatabase;

  ShinyHuntDao(this._getDatabase);

  /// Returns all shiny hunts from local SQLite, optionally including soft-deleted entries.
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'shiny_hunts',
      where: includeDeleted ? null : 'deleted_at = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => ShinyHunt.fromMap(m)).toList();
  }

  /// Retrieves a single shiny hunt by [id], or `null` if not found.
  Future<ShinyHunt?> getShinyHunt(String id) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'shiny_hunts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ShinyHunt.fromMap(maps.first);
  }

  /// Inserts or updates [hunt] non-destructively in local SQLite.
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    final db = await _getDatabase();
    final map = hunt.toMap();
    map['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;

    final cols = map.keys.toList();
    final placeholders = cols.map((_) => '?').join(', ');
    final updateSets = cols
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = '''
      INSERT INTO shiny_hunts (${cols.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(id) DO UPDATE SET $updateSets
    ''';

    await db.rawInsert(sql, cols.map((c) => map[c]).toList());
  }

  /// Deletes a shiny hunt by [id], either soft-delete (default) or permanent delete.
  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) async {
    final db = await _getDatabase();
    if (softDelete) {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.update(
        'shiny_hunts',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        'shiny_hunts',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
