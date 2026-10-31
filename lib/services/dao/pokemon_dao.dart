import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/pokemon.dart';
import '../../models/special_dex_models.dart';
import '../../models/ribbon.dart';

/// Data Access Object providing read-only query operations and in-memory caching
/// for reference Pokédex data (`pokedex.sqlite`).
class PokemonDao {
  final Future<Database> Function() _getDatabase;

  PokemonDao(this._getDatabase);

  // In-memory caches for static pokedex reference data to eliminate repeated SQLite querying
  List<Ribbon>? _cachedRibbons;
  final Map<int, List<String>> _versionGroupsCache = {};
  final Map<int, Map<String, dynamic>?> _evolutionChainCache = {};
  final Map<String, Map<String, dynamic>?> _matchingBallsCache = {};
  final Map<int, Map<String, Map<String, List<String>>>?> _encountersCache = {};
  final Map<int, int> _defaultLevelsCache = {};
  final Map<int, List<String>> _shinyCategoriesCache = {};
  List<Map<String, dynamic>>? _cachedShinyLocks;

  /// Clears in-memory caches of static reference data.
  void clearMemoryCache() {
    _cachedRibbons = null;
    _cachedShinyLocks = null;
    _versionGroupsCache.clear();
    _evolutionChainCache.clear();
    _matchingBallsCache.clear();
    _encountersCache.clear();
    _defaultLevelsCache.clear();
    _shinyCategoriesCache.clear();
  }

  /// Returns all shiny locks defined for [pokemonId] from reference SQLite database.
  Future<List<Map<String, dynamic>>> getShinyLocks(int pokemonId) async {
    final allLocks = await getAllShinyLocks();
    return allLocks
        .where((lock) => (lock['pokemon_id'] as num?)?.toInt() == pokemonId)
        .toList();
  }

  /// Returns all shiny locks recorded in the reference database.
  Future<List<Map<String, dynamic>>> getAllShinyLocks() async {
    if (_cachedShinyLocks != null) return _cachedShinyLocks!;

    try {
      final db = await _getDatabase();
      final results = await db.query('shiny_locks');
      if (results.isNotEmpty) {
        _cachedShinyLocks = results;
        return _cachedShinyLocks!;
      }
    } catch (e) {
      debugPrint('Database query for shiny_locks failed: $e');
    }

    _cachedShinyLocks = const [];
    return _cachedShinyLocks!;
  }

  /// Returns all Pokémon from the reference database including their forms.
  Future<List<Pokemon>> getAllPokemon() async {
    final db = await _getDatabase();
    final pokeMaps = await db.query('pokemon');
    final formMaps = await db.query('forms');

    Map<int, List<PokemonForm>> formsByPoke = {};
    for (var f in formMaps) {
      int pId = (f['pokemon_id'] as num?)?.toInt() ?? 0;
      formsByPoke.putIfAbsent(pId, () => []).add(PokemonForm.fromMap(f));
    }

    return pokeMaps
        .map(
          (p) => Pokemon.fromMap(
            p,
            formsByPoke[(p['id'] as num?)?.toInt() ?? 0] ?? [],
          ),
        )
        .toList();
  }

  /// Returns an index mapping of all regional and special Pokédex names to ordered lists of Pokémon IDs.
  Future<Map<String, List<int>>> getAllDexOrders() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'dex_orders',
      orderBy: 'dex_name ASC, order_index ASC',
    );

    Map<String, List<int>> result = {};
    for (var m in maps) {
      String dexName = m['dex_name']?.toString() ?? '';
      int pId = (m['pokemon_id'] as num?)?.toInt() ?? 0;
      result.putIfAbsent(dexName, () => []).add(pId);
    }

    final specialMaps = await db.query('special_dexes');
    for (var m in specialMaps) {
      String dexName = m['dex_name']?.toString().replaceAll('-', '_') ?? '';
      int pId = (m['pokemon_id'] as num?)?.toInt() ?? 0;
      result.putIfAbsent(dexName, () => []).add(pId);
    }

    result['national_overall'] = result['paldea_national'] ?? [];
    return result;
  }

  /// Returns a map associating Pokéball identifiers with their icon URLs.
  Future<Map<String, String>> getBallUrls() async {
    final db = await _getDatabase();
    final maps = await db.query('ball_urls');
    Map<String, String> result = {};
    for (var m in maps) {
      result[m['ball_name']?.toString() ?? ''] =
          m['image_url']?.toString() ?? '';
    }
    return result;
  }

  /// Returns wild encounter locations and methods for [pokemonId] grouped by generation and version.
  Future<Map<String, Map<String, List<String>>>?> getEncounters(
    int pokemonId,
  ) async {
    if (_encountersCache.containsKey(pokemonId)) {
      return _encountersCache[pokemonId];
    }
    final db = await _getDatabase();
    final maps = await db.query(
      'encounters',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );

    if (maps.isEmpty) {
      _encountersCache[pokemonId] = null;
      return null;
    }

    Map<String, Map<String, List<String>>> result = {};
    for (var map in maps) {
      String gen = map['gen']?.toString() ?? '';
      String version = map['version']?.toString() ?? '';
      String locData = map['location_data']?.toString() ?? '';

      result.putIfAbsent(gen, () => {});
      result[gen]![version] = locData.split('|||||');
    }
    _encountersCache[pokemonId] = result;
    return result;
  }

  /// Returns the parsed JSON evolution chain for [chainId], or `null` if not found.
  Future<Map<String, dynamic>?> getEvolutionChain(int chainId) async {
    if (chainId == -1) return null;
    if (_evolutionChainCache.containsKey(chainId)) {
      return _evolutionChainCache[chainId];
    }
    final db = await _getDatabase();
    final maps = await db.query(
      'evolutions',
      where: 'chain_id = ?',
      whereArgs: [chainId],
    );
    if (maps.isNotEmpty) {
      final res = jsonDecode(maps.first['chain_json']?.toString() ?? '{}');
      _evolutionChainCache[chainId] = res;
      return res;
    }
    _evolutionChainCache[chainId] = null;
    return null;
  }

  /// Returns legal and recommended Pokéball lists for [uniqueId] in normal and shiny variations.
  Future<Map<String, dynamic>?> getMatchingBalls(String uniqueId) async {
    if (_matchingBallsCache.containsKey(uniqueId)) {
      return _matchingBallsCache[uniqueId];
    }
    final db = await _getDatabase();
    var maps = await db.query(
      'matching_balls',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
    if (maps.isEmpty && !uniqueId.contains('_')) {
      maps = await db.query(
        'matching_balls',
        where: 'unique_id = ?',
        whereArgs: ['${uniqueId}_normal'],
      );
    }
    if (maps.isNotEmpty) {
      String nb = maps.first['normal_balls']?.toString() ?? 'any_ball';
      String sb = maps.first['shiny_balls']?.toString() ?? 'any_ball';
      final res = {
        'normal': nb == 'any_ball' ? [] : nb.split(','),
        'shiny': sb == 'any_ball' ? [] : sb.split(','),
      };
      _matchingBallsCache[uniqueId] = res;
      return res;
    }
    _matchingBallsCache[uniqueId] = null;
    return null;
  }

  Future<List<int>?> getGen1BaseStats(int pokemonId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'gen1_base_stats',
      where: 'id = ?',
      whereArgs: [pokemonId],
    );
    if (maps.isNotEmpty) {
      final m = maps.first;
      return [
        (m['hp'] as num).toInt(),
        (m['atk'] as num).toInt(),
        (m['def'] as num).toInt(),
        (m['spc'] as num).toInt(),
        (m['spe'] as num).toInt(),
      ];
    }
    return null;
  }

  Future<Map<int, Map<String, dynamic>>> getGen12PreEvolutions() async {
    final db = await _getDatabase();
    final maps = await db.query('gen12_pre_evolutions');
    Map<int, Map<String, dynamic>> result = {};
    for (var m in maps) {
      result[(m['id'] as num).toInt()] = {
        'pre': (m['pre_id'] as num).toInt(),
        'req': m['req'].toString(),
      };
    }
    return result;
  }

  Future<int> getDefaultLevel(int pokemonId) async {
    if (_defaultLevelsCache.containsKey(pokemonId)) {
      return _defaultLevelsCache[pokemonId]!;
    }
    final db = await _getDatabase();
    final maps = await db.query(
      'default_levels',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );
    final res = maps.isNotEmpty ? (maps.first['default_level'] as num).toInt() : 15;
    _defaultLevelsCache[pokemonId] = res;
    return res;
  }

  Future<List<String>> getShinyCategories(int pokemonId) async {
    if (_shinyCategoriesCache.containsKey(pokemonId)) {
      return _shinyCategoriesCache[pokemonId]!;
    }
    final db = await _getDatabase();
    final maps = await db.query(
      'shiny_categories',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );
    final res = maps.map((m) => m['category'] as String).toList();
    _shinyCategoriesCache[pokemonId] = res;
    return res;
  }

  Future<List<PokeAbility>> getAllAbilities() async {
    final db = await _getDatabase();
    final maps = await db.query('abilities', orderBy: 'id ASC');
    return maps
        .map(
          (m) => PokeAbility(
            id: m['id'] as int,
            nameDe: m['name_de'] as String,
            nameEn: m['name_en'] as String,
            descDe: m['desc_de'] as String,
            descEn: m['desc_en'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokeMove>> getAllMoves() async {
    final db = await _getDatabase();
    final maps = await db.query('moves', orderBy: 'id ASC');
    return maps
        .map(
          (m) => PokeMove(
            id: m['id'] as int,
            nameDe: m['name_de'] as String,
            nameEn: m['name_en'] as String,
            type: m['type'] as String,
            power: m['power'] as int? ?? 0,
            accuracy: m['accuracy'] as int? ?? 0,
            pp: m['pp'] as int? ?? 0,
            damageClass: m['damage_class'] as String,
            descDe: m['desc_de'] as String,
            descEn: m['desc_en'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokemonLearnset>> getPokemonForMove(int moveId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'pokemon_moves',
      where: 'move_id = ?',
      whereArgs: [moveId],
    );
    return maps
        .map(
          (m) => PokemonLearnset(
            pokemonId: m['pokemon_id'] as int,
            learnMethod: m['learn_method'] as String,
            levelLearned: m['level_learned'] as int,
            versionGroup: m['version_group'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokemonLearnset>> getPokemonForAbility(int abilityId) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'pokemon_abilities',
      where: 'ability_id = ?',
      whereArgs: [abilityId],
    );
    return maps
        .map(
          (m) => PokemonLearnset(
            pokemonId: m['pokemon_id'] as int,
            learnMethod: 'ability',
            levelLearned: 0,
            versionGroup: 'all',
            isHiddenAbility: (m['is_hidden'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<List<Ribbon>> getAllRibbons() async {
    if (_cachedRibbons != null) {
      return _cachedRibbons!;
    }
    final db = await _getDatabase();
    final maps = await db.query('ribbons');
    _cachedRibbons = maps.map((m) => Ribbon.fromMap(m)).toList();
    return _cachedRibbons!;
  }

  Future<List<String>> getAvailableVersionGroups(int pokemonId) async {
    if (_versionGroupsCache.containsKey(pokemonId)) {
      return _versionGroupsCache[pokemonId]!;
    }
    final db = await _getDatabase();
    final maps = await db.query(
      'pokemon_moves',
      columns: ['version_group'],
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
      distinct: true,
    );
    final res = maps.map((m) => m['version_group'] as String).toList();
    _versionGroupsCache[pokemonId] = res;
    return res;
  }

  Future<int> getBasePokemonId(int chainId) async {
    if (chainId == -1) return -1;
    final db = await _getDatabase();
    final maps = await db.query(
      'evolutions',
      where: 'chain_id = ?',
      whereArgs: [chainId],
    );
    if (maps.isNotEmpty) {
      final data = jsonDecode(maps.first['chain_json']?.toString() ?? '{}');
      if (data['species_id'] != null) {
        return (data['species_id'] as num).toInt();
      }
    }
    return -1;
  }

  Future<List<Map<String, dynamic>>> getSpecialObtainables() async {
    final db = await _getDatabase();
    return await db.query('special_obtainable');
  }

  /// Retrieves localized gender difference descriptions for a given [pokemonId],
  /// or `null` if the Pokémon species does not exhibit gender differences.
  Future<Map<String, String>?> getGenderDifference(int pokemonId) async {
    if (pokemonId <= 0) return null;
    final db = await _getDatabase();
    final res = await db.query(
      'gender_differences',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return {
        'de': res.first['difference_de']?.toString() ?? '',
        'en': res.first['difference_en']?.toString() ?? '',
      };
    }
    return null;
  }
}
