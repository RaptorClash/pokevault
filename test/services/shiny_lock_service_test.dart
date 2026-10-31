import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/shiny_lock_service.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('shiny_lock_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ShinyLockService Tests (TDD)', () {
    late Pokemon victini;
    late Pokemon cosmog;
    late Pokemon ogerpon;
    late Pokemon pikachu;
    late Pokemon poliwhirl;
    late Pokemon alolanRattata;

    setUp(() {
      victini = Pokemon(
        id: 494,
        nameDe: 'Victini',
        nameEn: 'Victini',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 3,
        evolutionChainId: 253,
        eggGroups: ['no-eggs'],
        weight: 4.0,
        speed: 100,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 5,
            imageId: 494,
            types: ['psychic', 'fire'],
            exclusiveRegions: [],
          ),
        ],
      );

      cosmog = Pokemon(
        id: 789,
        nameDe: 'Cosmog',
        nameEn: 'Cosmog',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 45,
        evolutionChainId: 413,
        eggGroups: ['no-eggs'],
        weight: 0.1,
        speed: 37,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 7,
            imageId: 789,
            types: ['psychic'],
            exclusiveRegions: [],
          ),
        ],
      );

      ogerpon = Pokemon(
        id: 1017,
        nameDe: 'Ogerpon',
        nameEn: 'Ogerpon',
        hasGenderDifferences: false,
        genderRate: 0,
        captureRate: 5,
        evolutionChainId: 539,
        eggGroups: ['no-eggs'],
        weight: 39.8,
        speed: 110,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 9,
            imageId: 1017,
            types: ['grass'],
            exclusiveRegions: [],
          ),
        ],
      );

      pikachu = Pokemon(
        id: 25,
        nameDe: 'Pikachu',
        nameEn: 'Pikachu',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 10,
        eggGroups: ['field', 'fairy'],
        weight: 6.0,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 25,
            types: ['electric'],
            exclusiveRegions: [],
          ),
        ],
      );

      poliwhirl = Pokemon(
        id: 61,
        nameDe: 'Quaputzi',
        nameEn: 'Poliwhirl',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 26,
        eggGroups: ['water1'],
        weight: 20.0,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 61,
            types: ['water'],
            exclusiveRegions: [],
          ),
        ],
      );

      alolanRattata = Pokemon(
        id: 19,
        nameDe: 'Rattfratz',
        nameEn: 'Rattata',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 7,
        eggGroups: ['field'],
        weight: 3.8,
        speed: 72,
        forms: [
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 19,
            types: ['dark', 'normal'],
            exclusiveRegions: [],
          ),
        ],
      );
    });

    test('Global shiny locks are identified for all games', () {
      final victiniEntry = DexDisplayEntry(
        pokemon: victini,
        uniqueId: '494_normal',
        displaySuffix: '',
        imageUrl: '',
      );
      final cosmogEntry = DexDisplayEntry(
        pokemon: cosmog,
        uniqueId: '789_normal',
        displaySuffix: '',
        imageUrl: '',
      );
      final ogerponEntry = DexDisplayEntry(
        pokemon: ogerpon,
        uniqueId: '1017_normal',
        displaySuffix: '',
        imageUrl: '',
      );
      final pikachuEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl: '',
      );

      expect(ShinyLockService.isShinyLocked(victiniEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(cosmogEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(ogerponEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(pikachuEntry), isFalse);
    });

    test('In-Game Trades with fixed DVs are shiny locked', () {
      final sunMoonTradePoliwhirl = DexDisplayEntry(
        pokemon: poliwhirl,
        uniqueId: '61_special_128_trade_alola_normal',
        displaySuffix: ' (Tausche - Pokémon Sun and Moon)',
        imageUrl: '',
      );

      expect(ShinyLockService.isShinyLocked(sunMoonTradePoliwhirl), isTrue);

      final lockReason = ShinyLockService.getShinyLockReason(
        sunMoonTradePoliwhirl,
        lang: 'de',
      );
      expect(lockReason, contains('Tausch'));
    });

    test('Lets Go Alolan in-game trades can be shiny and are not locked', () {
      final letsGoTradeRattata = DexDisplayEntry(
        pokemon: alolanRattata,
        uniqueId: '19_special_10_trade_kanto_alola',
        displaySuffix: " (Tausche - Let's Go, Pikachu!)",
        imageUrl: '',
      );

      expect(ShinyLockService.isShinyLocked(letsGoTradeRattata), isFalse);
    });

    test('isUniqueIdShinyLocked correctly detects locks by uniqueId string', () {
      // Global locks
      expect(ShinyLockService.isUniqueIdShinyLocked('494_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('789_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('1017_normal'), isTrue);

      // Special form locks
      expect(ShinyLockService.isUniqueIdShinyLocked('658_ash'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('901_bloodmoon'), isTrue);

      // In-game trades
      expect(ShinyLockService.isUniqueIdShinyLocked('61_special_128_trade_alola_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('19_special_10_trade_kanto_alola'), isFalse);

      // Normal unlocked
      expect(ShinyLockService.isUniqueIdShinyLocked('25_normal'), isFalse);

      // Region locks
      expect(ShinyLockService.isUniqueIdShinyLocked('382_normal', dexRegion: 'hoenn'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('382_normal', dexRegion: 'kanto'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('888_normal', dexRegion: 'galar'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('1007_normal', dexRegion: 'paldea'), isTrue);
    });

    test("N's Pokémon from Black 2 / White 2 are detected as shiny locked", () {
      final purrloin = Pokemon(
        id: 509,
        nameDe: 'Felilou',
        nameEn: 'Purrloin',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 260,
        eggGroups: ['field'],
        weight: 10.1,
        speed: 66,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 5,
            imageId: 509,
            types: ['dark'],
            exclusiveRegions: [],
          ),
        ],
      );

      final zorua = Pokemon(
        id: 570,
        nameDe: 'Zorua',
        nameEn: 'Zorua',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 75,
        evolutionChainId: 292,
        eggGroups: ['field'],
        weight: 12.5,
        speed: 65,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 5,
            imageId: 570,
            types: ['dark'],
            exclusiveRegions: [],
          ),
        ],
      );

      // Entry with _n_ in uniqueId and displaySuffix
      final nPurrloin = DexDisplayEntry(
        pokemon: purrloin,
        uniqueId: '509_special_325_n_unova_normal',
        displaySuffix: " (N's Pokémon)",
        imageUrl: '',
      );

      // Entry with special ID 336 (N's Zorua) and specType 'n'
      final nZorua = DexDisplayEntry(
        pokemon: zorua,
        uniqueId: '570_special_336_n_unova_normal',
        displaySuffix: " (N's Pokémon)",
        imageUrl: '',
      );

      // Regular Purrloin (should NOT be locked)
      final regularPurrloin = DexDisplayEntry(
        pokemon: purrloin,
        uniqueId: '509_normal',
        displaySuffix: '',
        imageUrl: '',
      );

      // Regular Zorua (should NOT be locked)
      final regularZorua = DexDisplayEntry(
        pokemon: zorua,
        uniqueId: '570_normal',
        displaySuffix: '',
        imageUrl: '',
      );

      // isShinyLocked checks
      expect(ShinyLockService.isShinyLocked(nPurrloin), isTrue);
      expect(ShinyLockService.isShinyLocked(nZorua), isTrue);
      expect(ShinyLockService.isShinyLocked(regularPurrloin), isFalse);
      expect(ShinyLockService.isShinyLocked(regularZorua), isFalse);

      // isUniqueIdShinyLocked checks
      expect(ShinyLockService.isUniqueIdShinyLocked('509_special_325_n_unova_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('570_special_336_n_unova_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('555_special_333_n_unova_normal__box1'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('509_special_325_gift_unova_normal'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('509_normal'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('570_normal'), isFalse);

      // Explanatory reasons
      final reasonDe = ShinyLockService.getShinyLockReason(nPurrloin, lang: 'de');
      expect(reasonDe, contains("N's Pokémon"));
      expect(reasonDe, anyOf(contains('Schwarz 2'), contains('Black 2')));

      final reasonEn = ShinyLockService.getShinyLockReason(nPurrloin, lang: 'en');
      expect(reasonEn, contains("N's Pokémon"));
      expect(reasonEn, contains('Black 2'));
    });

    test("Adversarial & Edge Cases for N's Pokémon detection", () async {
      // 1. All 15 known B2W2 N's Pokémon special IDs (325 through 339)
      for (int sId = 325; sId <= 339; sId++) {
        expect(ShinyLockService.nPokemonSpecialIds.contains(sId), isTrue);
        expect(ShinyLockService.isUniqueIdShinyLocked('509_special_${sId}_gift_unova_normal'), isTrue);
        expect(ShinyLockService.isUniqueIdShinyLocked('509_special_${sId}_n_unova_normal'), isTrue);
        expect(ShinyLockService.isUniqueIdShinyLocked('509_special_${sId}_n_unova_normal__box_custom_42'), isTrue);
      }

      // 2. Names or forms containing letter 'n' must NOT be falsely identified as N's Pokémon
      expect(ShinyLockService.isNPokemonId('149_normal'), isFalse);
      expect(ShinyLockService.isNPokemonId('25_normal'), isFalse);
      expect(ShinyLockService.isNPokemonId('643_normal'), isFalse);
      expect(ShinyLockService.isNPokemonId('800_dawn_wings'), isFalse);
      expect(ShinyLockService.isNPokemonId('1014_normal'), isFalse);

      // 3. Malformed or boundary uniqueIds
      expect(ShinyLockService.isNPokemonId(''), isFalse);
      expect(ShinyLockService.isNPokemonId('random_string'), isFalse);
      expect(ShinyLockService.isNPokemonId('100_n'), isFalse);
      expect(ShinyLockService.isNPokemonId('n_test'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked(''), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('not_a_pokemon_id'), isFalse);

      // Critical Bug Regression: Unown Form N (id 201, form 'n', uniqueId '201_n')
      // MUST NOT be falsely identified as N's Pokémon or shiny locked!
      final unown = Pokemon(
        id: 201,
        nameDe: 'Icognito',
        nameEn: 'Unown',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 225,
        evolutionChainId: 99,
        eggGroups: ['no-eggs'],
        weight: 5.0,
        speed: 48,
        forms: [
          PokemonForm(
            name: 'n',
            formType: 'unown',
            minGen: 2,
            imageId: 201,
            types: ['psychic'],
            exclusiveRegions: [],
          ),
        ],
      );

      final unownNEntry = DexDisplayEntry(
        pokemon: unown,
        uniqueId: '201_n',
        displaySuffix: ' (N)',
        imageUrl: '',
        form: unown.forms.first,
      );

      expect(ShinyLockService.isNPokemonId('201_n'), isFalse);
      expect(ShinyLockService.isNPokemonId('201_n__box1'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('201_n'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('201_n__box1'), isFalse);
      expect(ShinyLockService.isNPokemon(unownNEntry), isFalse);
      expect(ShinyLockService.isShinyLocked(unownNEntry), isFalse);

      // 4. Async check against database
      final purrloin = Pokemon(
        id: 509,
        nameDe: 'Felilou',
        nameEn: 'Purrloin',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 260,
        eggGroups: ['field'],
        weight: 10.1,
        speed: 66,
        forms: [],
      );

      final nPurrloin = DexDisplayEntry(
        pokemon: purrloin,
        uniqueId: '509_special_325_n_unova_normal',
        displaySuffix: " (N's Pokémon)",
        imageUrl: '',
      );

      final isLockedAsync = await ShinyLockService.isShinyLockedAsync(nPurrloin);
      expect(isLockedAsync, isTrue);
    });

    test('DatabaseService getShinyLocks and getAllShinyLocks retrieve locks from DB', () async {
      final allLocks = await DatabaseService.instance.getAllShinyLocks();
      expect(allLocks, isNotEmpty);

      final victiniLocks = await DatabaseService.instance.getShinyLocks(494);
      expect(victiniLocks, isNotEmpty);
      expect(victiniLocks.any((l) => l['lock_type'] == 'global'), isTrue);

      final poliwhirlLocks = await DatabaseService.instance.getShinyLocks(61);
      expect(poliwhirlLocks, isNotEmpty);
      expect(poliwhirlLocks.any((l) => l['lock_type'] == 'trade'), isTrue);
    });

    test('DatabaseService getAllShinyLocks returns empty list if db query returns no rows without fallback', () async {
      final mockDb = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('CREATE TABLE shiny_locks (pokemon_id INTEGER, pokemon_name TEXT)');
      });
      DatabaseService.setAppDatabaseForTesting(mockDb);
      DatabaseService.instance.clearMemoryCache();

      final locks = await DatabaseService.instance.getAllShinyLocks();
      expect(locks, isEmpty);

      // Restore original DB
      DatabaseService.setAppDatabaseForTesting(null);
      DatabaseService.instance.clearMemoryCache();
      await mockDb.close();
    });

    test('Sceptile vc_glitch form has correct Grass type and not Dragon type', () async {
      final db = await DatabaseService.instance.appDatabase;
      final rows = await db.query(
        'forms',
        where: 'pokemon_id = ? AND name = ?',
        whereArgs: [254, 'vc_glitch'],
      );
      expect(rows, isNotEmpty);
      final form = PokemonForm.fromMap(rows.first);
      expect(form.types, equals(['grass']));
      expect(form.types, isNot(contains('dragon')));
    });
  });
}
