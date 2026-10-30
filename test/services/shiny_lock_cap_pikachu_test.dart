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
import 'package:pokevault/utils/shiny_logic_helper.dart';

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
    tempDir = Directory.systemTemp.createTempSync('cap_pikachu_test_');
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

  group('Cap Pikachu Shiny Locks & Alpha Eligibility Tests (TDD)', () {
    late Pokemon pikachu;
    late PokemonForm normalForm;
    late PokemonForm originalCapForm;
    late PokemonForm hoennCapForm;
    late PokemonForm sinnohCapForm;
    late PokemonForm unovaCapForm;
    late PokemonForm kalosCapForm;
    late PokemonForm alolaCapForm;
    late PokemonForm partnerCapForm;
    late PokemonForm worldCapForm;

    setUp(() {
      normalForm = PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      );
      originalCapForm = PokemonForm(
        name: 'original-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10094,
        types: ['electric'],
        exclusiveRegions: [],
      );
      hoennCapForm = PokemonForm(
        name: 'hoenn-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10095,
        types: ['electric'],
        exclusiveRegions: [],
      );
      sinnohCapForm = PokemonForm(
        name: 'sinnoh-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10096,
        types: ['electric'],
        exclusiveRegions: [],
      );
      unovaCapForm = PokemonForm(
        name: 'unova-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10097,
        types: ['electric'],
        exclusiveRegions: [],
      );
      kalosCapForm = PokemonForm(
        name: 'kalos-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10098,
        types: ['electric'],
        exclusiveRegions: [],
      );
      alolaCapForm = PokemonForm(
        name: 'alola-cap',
        formType: 'regional',
        minGen: 7,
        imageId: 10099,
        types: ['electric'],
        exclusiveRegions: [],
      );
      partnerCapForm = PokemonForm(
        name: 'partner-cap',
        formType: 'other',
        minGen: 7,
        imageId: 10148,
        types: ['electric'],
        exclusiveRegions: [],
      );
      worldCapForm = PokemonForm(
        name: 'world-cap',
        formType: 'other',
        minGen: 8,
        imageId: 10160,
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
          normalForm,
          originalCapForm,
          hoennCapForm,
          sinnohCapForm,
          unovaCapForm,
          kalosCapForm,
          alolaCapForm,
          partnerCapForm,
          worldCapForm,
        ],
      );
    });

    test('Regular Pikachu is not shiny locked', () {
      final entry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl: '',
        form: normalForm,
      );
      expect(ShinyLockService.isShinyLocked(entry), isFalse);
      expect(ShinyLockService.isUniqueIdShinyLocked('25_normal'), isFalse);
    });

    test('All Cap Pikachu forms except partner-cap in USUM are shiny-locked', () {
      final nonPartnerCaps = [
        originalCapForm,
        hoennCapForm,
        sinnohCapForm,
        unovaCapForm,
        kalosCapForm,
        alolaCapForm,
        worldCapForm,
      ];

      for (final form in nonPartnerCaps) {
        final entry = DexDisplayEntry(
          pokemon: pikachu,
          uniqueId: '25_${form.name}',
          displaySuffix: ' (${form.name})',
          imageUrl: '',
          form: form,
        );

        expect(
          ShinyLockService.isShinyLocked(entry),
          isTrue,
          reason: '${form.name} should be shiny locked in national dex',
        );
        expect(
          ShinyLockService.isShinyLocked(entry, dexRegion: 'updated_alola_regional'),
          isTrue,
          reason: '${form.name} should be shiny locked in USUM',
        );
        expect(
          ShinyLockService.isShinyLocked(entry, dexRegion: 'galar'),
          isTrue,
          reason: '${form.name} should be shiny locked in Galar',
        );
        expect(
          ShinyLockService.isUniqueIdShinyLocked('25_${form.name}'),
          isTrue,
          reason: '25_${form.name} uniqueId should be shiny locked',
        );
      }
    });

    test('partner-cap Pikachu CAN be shiny in USUM (updated_alola_regional) and National Dex', () {
      final partnerCapEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_partner-cap',
        displaySuffix: ' (Partner-Kappe)',
        imageUrl: '',
        form: partnerCapForm,
      );

      // In USUM, Partner Cap Pikachu was obtainable shiny via the Pikachu Valley QR Code
      expect(
        ShinyLockService.isShinyLocked(partnerCapEntry, dexRegion: 'updated_alola_regional'),
        isFalse,
      );
      expect(
        ShinyLockService.isUniqueIdShinyLocked('25_partner-cap', dexRegion: 'updated_alola_regional'),
        isFalse,
      );

      // In National Dex, because it was legitimately obtainable shiny in USUM, it is not globally locked
      expect(
        ShinyLockService.isShinyLocked(partnerCapEntry),
        isFalse,
      );
      expect(
        ShinyLockService.isShinyLocked(partnerCapEntry, dexRegion: 'national_overall'),
        isFalse,
      );
      expect(
        ShinyLockService.isUniqueIdShinyLocked('25_partner-cap'),
        isFalse,
      );

      // In Galar / Paldea / original Sun&Moon, Partner Cap Pikachu cannot be shiny
      expect(
        ShinyLockService.isShinyLocked(partnerCapEntry, dexRegion: 'galar'),
        isTrue,
      );
      expect(
        ShinyLockService.isShinyLocked(partnerCapEntry, dexRegion: 'alola_regional'),
        isTrue,
      );
      expect(
        ShinyLockService.isUniqueIdShinyLocked('25_partner-cap', dexRegion: 'galar'),
        isTrue,
      );
    });

    test('ShinyLock reason for Cap Pikachu returns informative text', () {
      final originalCapEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_original-cap',
        displaySuffix: '',
        imageUrl: '',
        form: originalCapForm,
      );

      final reasonDe = ShinyLockService.getShinyLockReason(originalCapEntry, lang: 'de');
      final reasonEn = ShinyLockService.getShinyLockReason(originalCapEntry, lang: 'en');

      expect(reasonDe, contains('Kappe'));
      expect(reasonEn, contains('Cap'));
    });

    test('Cap Pikachu forms are NEVER alpha eligible in Hisui or anywhere', () async {
      final normalEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl: '',
        form: normalForm,
      );
      // Regular Pikachu can be Alpha in Hisui
      expect(await DexLogicHelper.isAlphaEligible(normalEntry), isTrue);

      final capForms = [
        originalCapForm,
        hoennCapForm,
        sinnohCapForm,
        unovaCapForm,
        kalosCapForm,
        alolaCapForm,
        partnerCapForm,
        worldCapForm,
      ];

      for (final form in capForms) {
        final capEntry = DexDisplayEntry(
          pokemon: pikachu,
          uniqueId: '25_${form.name}',
          displaySuffix: ' (${form.name})',
          imageUrl: '',
          form: form,
        );
        expect(
          await DexLogicHelper.isAlphaEligible(capEntry),
          isFalse,
          reason: '${form.name} must NOT be alpha eligible',
        );
      }
    });

    test('ShinyLogicHelper provides explicit note for Partner Cap Pikachu shiny appearance', () {
      final partnerCapEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_partner-cap',
        displaySuffix: ' (Partner-Kappe)',
        imageUrl: '',
        form: partnerCapForm,
      );

      expect(ShinyLogicHelper.isPartnerCapPikachu(partnerCapEntry), isTrue);

      final noteDe = ShinyLogicHelper.getPartnerCapShinyNote(lang: 'de');
      final noteEn = ShinyLogicHelper.getPartnerCapShinyNote(lang: 'en');

      expect(noteDe, contains('Stern'));
      expect(noteDe, contains('Animation'));
      expect(noteDe, contains('Farbe'));

      expect(noteEn, contains('star'));
      expect(noteEn, contains('sparkle'));
      expect(noteEn, contains('color'));
    });
  });
}
