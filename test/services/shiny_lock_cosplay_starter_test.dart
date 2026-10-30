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
import 'package:pokevault/utils/dex_logic_helper.dart';

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
    tempDir = Directory.systemTemp.createTempSync('cosplay_starter_test_');
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

  group('Cosplay Pikachu & Starter Pikachu/Eevee Shiny Locks & Alpha Eligibility (TDD)', () {
    late Pokemon pikachu;
    late Pokemon eevee;

    late PokemonForm pikaNormal;
    late PokemonForm pikaCosplay;
    late PokemonForm pikaRockStar;
    late PokemonForm pikaBelle;
    late PokemonForm pikaPopStar;
    late PokemonForm pikaPhd;
    late PokemonForm pikaLibre;
    late PokemonForm pikaStarter;

    late PokemonForm eeveeNormal;
    late PokemonForm eeveeStarter;

    setUp(() {
      pikaNormal = PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaCosplay = PokemonForm(
        name: 'cosplay',
        formType: 'other',
        minGen: 6,
        imageId: 10080,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaRockStar = PokemonForm(
        name: 'rock-star',
        formType: 'other',
        minGen: 6,
        imageId: 10081,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaBelle = PokemonForm(
        name: 'belle',
        formType: 'other',
        minGen: 6,
        imageId: 10082,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaPopStar = PokemonForm(
        name: 'pop-star',
        formType: 'other',
        minGen: 6,
        imageId: 10083,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaPhd = PokemonForm(
        name: 'phd',
        formType: 'other',
        minGen: 6,
        imageId: 10084,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaLibre = PokemonForm(
        name: 'libre',
        formType: 'other',
        minGen: 6,
        imageId: 10085,
        types: ['electric'],
        exclusiveRegions: [],
      );
      pikaStarter = PokemonForm(
        name: 'starter',
        formType: 'other',
        minGen: 7,
        imageId: 10158,
        types: ['electric'],
        exclusiveRegions: [],
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
          pikaNormal,
          pikaCosplay,
          pikaRockStar,
          pikaBelle,
          pikaPopStar,
          pikaPhd,
          pikaLibre,
          pikaStarter,
        ],
      );

      eeveeNormal = PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: 133,
        types: ['normal'],
        exclusiveRegions: [],
      );
      eeveeStarter = PokemonForm(
        name: 'starter',
        formType: 'other',
        minGen: 7,
        imageId: 10159,
        types: ['normal'],
        exclusiveRegions: [],
      );

      eevee = Pokemon(
        id: 133,
        nameDe: 'Evoli',
        nameEn: 'Eevee',
        hasGenderDifferences: true,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 67,
        eggGroups: ['field'],
        weight: 6.5,
        speed: 55,
        forms: [
          eeveeNormal,
          eeveeStarter,
        ],
      );
    });

    test('All Cosplay Pikachu forms (ORAS) are 100% shiny-locked across all dex regions', () {
      final cosplayForms = [
        pikaCosplay,
        pikaRockStar,
        pikaBelle,
        pikaPopStar,
        pikaPhd,
        pikaLibre,
      ];

      for (final form in cosplayForms) {
        final entry = DexDisplayEntry(
          pokemon: pikachu,
          uniqueId: '25_${form.name}',
          displaySuffix: ' (${form.name})',
          imageUrl: '',
          form: form,
        );

        // National Dex check
        expect(
          ShinyLockService.isShinyLocked(entry),
          isTrue,
          reason: 'Pikachu form ${form.name} must be shiny-locked in national dex',
        );
        // Region-specific checks
        expect(
          ShinyLockService.isShinyLocked(entry, dexRegion: 'hoenn'),
          isTrue,
          reason: 'Pikachu form ${form.name} must be shiny-locked in Hoenn / ORAS',
        );
        expect(
          ShinyLockService.isShinyLocked(entry, dexRegion: 'kanto'),
          isTrue,
        );
        // UniqueId checks
        expect(
          ShinyLockService.isUniqueIdShinyLocked('25_${form.name}'),
          isTrue,
          reason: 'uniqueId 25_${form.name} must be shiny locked',
        );
        expect(
          ShinyLockService.isUniqueIdShinyLocked('25_${form.name}__0'),
          isTrue,
          reason: 'composite instance uniqueId 25_${form.name}__0 must be shiny locked',
        );
      }
    });

    test('Starter Pikachu and Starter Eevee (Let\'s Go) are 100% shiny-locked across all dex regions', () {
      final pikaStarterEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: pikaStarter,
      );

      expect(ShinyLockService.isShinyLocked(pikaStarterEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(pikaStarterEntry, dexRegion: 'kanto'), isTrue);
      expect(ShinyLockService.isShinyLocked(pikaStarterEntry, dexRegion: 'national'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_starter'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_starter__1'), isTrue);

      final eeveeStarterEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: eeveeStarter,
      );

      expect(ShinyLockService.isShinyLocked(eeveeStarterEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(eeveeStarterEntry, dexRegion: 'kanto'), isTrue);
      expect(ShinyLockService.isShinyLocked(eeveeStarterEntry, dexRegion: 'national'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('133_starter'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('133_starter__2'), isTrue);
    });

    test('Regular Pikachu and regular Eevee are NOT shiny-locked', () async {
      final pikaEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl: '',
        form: pikaNormal,
      );
      expect(ShinyLockService.isShinyLocked(pikaEntry), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_normal'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('25'), isFalse);
      expect(await ShinyLockService.isShinyLockedAsync(pikaEntry), isFalse);

      final eeveeEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_normal',
        displaySuffix: '',
        imageUrl: '',
        form: eeveeNormal,
      );
      expect(ShinyLockService.isShinyLocked(eeveeEntry), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('133_normal'), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('133'), isFalse);
      expect(await ShinyLockService.isShinyLockedAsync(eeveeEntry), isFalse);
    });

    test('isShinyLockedAsync returns true for all Cosplay Pikachu forms and Starter Pikachu/Eevee', () async {
      final cosplayForms = [
        pikaCosplay,
        pikaRockStar,
        pikaBelle,
        pikaPopStar,
        pikaPhd,
        pikaLibre,
      ];
      for (final form in cosplayForms) {
        final entry = DexDisplayEntry(
          pokemon: pikachu,
          uniqueId: '25_${form.name}',
          displaySuffix: ' (${form.name})',
          imageUrl: '',
          form: form,
        );
        expect(
          await ShinyLockService.isShinyLockedAsync(entry),
          isTrue,
          reason: 'isShinyLockedAsync must return true for Cosplay Pikachu ${form.name}',
        );
      }

      final pikaStarterEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: pikaStarter,
      );
      expect(await ShinyLockService.isShinyLockedAsync(pikaStarterEntry), isTrue);

      final eeveeStarterEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: eeveeStarter,
      );
      expect(await ShinyLockService.isShinyLockedAsync(eeveeStarterEntry), isTrue);
    });

    test('DatabaseService.instance.getShinyLocks returns global locks for cosplay forms and starter forms', () async {
      final pikaLocks = await DatabaseService.instance.getShinyLocks(25);
      final pikaLockForms = pikaLocks
          .where((l) => l['lock_type'] == 'global' && l['game_version'] == 'all')
          .map((l) => l['form_name'])
          .toSet();

      expect(pikaLockForms, containsAll([
        'cosplay',
        'rock-star',
        'belle',
        'pop-star',
        'phd',
        'libre',
        'starter',
      ]));

      final eeveeLocks = await DatabaseService.instance.getShinyLocks(133);
      final eeveeLockForms = eeveeLocks
          .where((l) => l['lock_type'] == 'global' && l['game_version'] == 'all')
          .map((l) => l['form_name'])
          .toSet();

      expect(eeveeLockForms, contains('starter'));
    });

    test('Cosplay Pikachu name variants (rockstar, rock_star, popstar, pop_star) and casing are handled', () {
      expect(ShinyLockService.isCosplayPikachuForm('rockstar'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('rock_star'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('Rock-Star'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('popstar'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('pop_star'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('Pop-Star'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('libre'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('LIBRE'), isTrue);
      expect(ShinyLockService.isCosplayPikachuForm('normal'), isFalse);
      expect(ShinyLockService.isCosplayPikachuForm(null), isFalse);

      expect(ShinyLockService.isUniqueIdShinyLocked('25_rockstar'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_rock_star'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_popstar'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_pop_star'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_STARTER'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('133_STARTER'), isTrue);
    });

    test('getShinyLockReason returns informative text for Cosplay Pikachu and Starter Pikachu/Eevee', () {
      final pikaCosplayEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_cosplay',
        displaySuffix: '',
        imageUrl: '',
        form: pikaCosplay,
      );

      final cosplayReasonDe = ShinyLockService.getShinyLockReason(pikaCosplayEntry, lang: 'de');
      final cosplayReasonEn = ShinyLockService.getShinyLockReason(pikaCosplayEntry, lang: 'en');
      expect(cosplayReasonDe.toLowerCase(), contains('cosplay'));
      expect(cosplayReasonEn.toLowerCase(), contains('cosplay'));

      final pikaStarterEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_starter',
        displaySuffix: '',
        imageUrl: '',
        form: pikaStarter,
      );
      final starterPikaReasonDe = ShinyLockService.getShinyLockReason(pikaStarterEntry, lang: 'de');
      final starterPikaReasonEn = ShinyLockService.getShinyLockReason(pikaStarterEntry, lang: 'en');
      expect(starterPikaReasonDe.toLowerCase(), contains('starter'));
      expect(starterPikaReasonEn.toLowerCase(), contains('starter'));

      final eeveeStarterEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_starter',
        displaySuffix: '',
        imageUrl: '',
        form: eeveeStarter,
      );
      final starterEeveeReasonDe = ShinyLockService.getShinyLockReason(eeveeStarterEntry, lang: 'de');
      final starterEeveeReasonEn = ShinyLockService.getShinyLockReason(eeveeStarterEntry, lang: 'en');
      expect(starterEeveeReasonDe.toLowerCase(), contains('starter'));
      expect(starterEeveeReasonEn.toLowerCase(), contains('starter'));
    });

    test('Alpha eligibility: Regular Pikachu & Eevee ARE alpha-eligible; Cosplay and Starters are NEVER alpha-eligible', () async {
      final pikaEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl: '',
        form: pikaNormal,
      );
      final eeveeEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_normal',
        displaySuffix: '',
        imageUrl: '',
        form: eeveeNormal,
      );

      // In Hisui, normal Pikachu and Eevee can be Alpha
      expect(await DexLogicHelper.isAlphaEligible(pikaEntry), isTrue);
      expect(await DexLogicHelper.isAlphaEligible(eeveeEntry), isTrue);

      // Cosplay Pikachu forms can NEVER be Alpha
      final cosplayForms = [
        pikaCosplay,
        pikaRockStar,
        pikaBelle,
        pikaPopStar,
        pikaPhd,
        pikaLibre,
      ];
      for (final form in cosplayForms) {
        final entry = DexDisplayEntry(
          pokemon: pikachu,
          uniqueId: '25_${form.name}',
          displaySuffix: ' (${form.name})',
          imageUrl: '',
          form: form,
        );
        expect(
          await DexLogicHelper.isAlphaEligible(entry),
          isFalse,
          reason: 'Cosplay form ${form.name} must NOT be alpha eligible',
        );
      }

      // Starter Pikachu and Starter Eevee can NEVER be Alpha
      final pikaStarterEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: pikaStarter,
      );
      expect(await DexLogicHelper.isAlphaEligible(pikaStarterEntry), isFalse);

      final eeveeStarterEntry = DexDisplayEntry(
        pokemon: eevee,
        uniqueId: '133_starter',
        displaySuffix: ' (Starter)',
        imageUrl: '',
        form: eeveeStarter,
      );
      expect(await DexLogicHelper.isAlphaEligible(eeveeStarterEntry), isFalse);
    });
  });
}
